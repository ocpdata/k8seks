# This module deploys NGINX Plus with NGINX One Agent on the EKS cluster

locals {
  nginx_agent_values = var.data_plane_key != "" ? trimspace(<<-YAML
controller:
  volumes:
    - name: nginx-agent-state
      emptyDir: {}
    - name: nginx-agent-log
      emptyDir: {}
${var.enable_waf ? "    - name: nap-compiler-state\n      emptyDir: {}" : ""}
  volumeMounts:
    - name: nginx-agent-state
      mountPath: /var/lib/nginx-agent
    - name: nginx-agent-log
      mountPath: /var/log/nginx-agent
${var.enable_waf ? "    - name: nap-compiler-state\n      mountPath: /opt/nms-nap-compiler" : ""}
YAML
  ) : ""

  controller_image_repository = var.enable_waf ? var.waf_image_repository : "private-registry.nginx.com/nginx-ic/nginx-plus-ingress"
  controller_image_tag        = var.enable_waf ? var.waf_image_tag : var.nginx_plus_image_tag

  nginx_agent_waf_config = trimspace(<<-YAML
log:
  level: info
  path: ""

allowed_directories:
  - /etc/nginx
  - /usr/lib/nginx/modules

features:
  - certificates
  - connection
  - metrics
  - file-watcher

command:
  server:
    host: agent.connect.nginx.com
    port: 443
  auth:
    tokenpath: "/etc/nginx-agent/secrets/dataplane.key"
  tls:
    skip_verify: false

nginx_app_protect:
  report_interval: 15s
  precompiled_publication: true

extensions:
  - nginx-app-protect

config_dirs: "/etc/nginx:/usr/local/etc/nginx:/usr/share/nginx/modules:/etc/nms:/etc/app_protect"
YAML
  )

  waf_controller_values = var.enable_waf ? trimspace(<<-YAML
controller:
  podSecurityContext:
    fsGroup: 101
  containerSecurityContext:
    runAsUser: 101
  initContainers:
    - name: fix-nginx-agent-permissions
      image: busybox:1.36
      command:
        - sh
        - -c
        - mkdir -p /etc/nginx/waf/bundles /etc/nginx/waf/nac-policies && chmod 644 /etc/nginx-agent/nginx-agent.conf
      volumeMounts:
        - name: app-protect-waf
          mountPath: /etc/nginx/waf
  extraVolumes:
    - name: app-protect-waf
      emptyDir: {}
  extraVolumeMounts:
    - name: app-protect-waf
      mountPath: /etc/nginx/waf
YAML
  ) : ""

  service_annotations = var.enable_nlb ? {
    "service.beta.kubernetes.io/aws-load-balancer-type"           = "nlb"
    "service.beta.kubernetes.io/aws-load-balancer-proxy-protocol" = "*"
  } : {}
}

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Create namespace for NGINX Plus
resource "kubernetes_namespace" "nginx" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name" = "nginx"
    }
  }
}

# Create secret for NGINX Plus license JWT
resource "kubernetes_secret" "nplus_license" {
  count = var.enabled && var.license_jwt != "" ? 1 : 0

  metadata {
    name      = "nplus-license"
    namespace = var.namespace
  }

  type = "nginx.com/license"

  data = {
    "license.jwt" = var.license_jwt
  }

  depends_on = [kubernetes_namespace.nginx]
}

# Create docker registry secret for private-registry.nginx.com
resource "kubernetes_secret" "regcred" {
  count = var.enabled && var.license_jwt != "" ? 1 : 0

  metadata {
    name      = "regcred"
    namespace = var.namespace
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "private-registry.nginx.com" = {
          username = trimspace(var.license_jwt)
          password = "none"
          auth     = base64encode("${trimspace(var.license_jwt)}:none")
        }
      }
    })
  }

  depends_on = [kubernetes_namespace.nginx]
}

# Create secret for NGINX One Agent dataplane key
resource "kubernetes_secret" "nginx_agent" {
  count = var.enabled && var.data_plane_key != "" ? 1 : 0

  metadata {
    name      = "nginx-agent"
    namespace = var.namespace
  }

  type = "Opaque"

  data = {
    "dataplane.key" = trimspace(var.data_plane_key)
  }

  depends_on = [kubernetes_namespace.nginx]
}

resource "kubernetes_config_map" "nginx_agent_waf_config" {
  count = var.enabled && var.enable_waf && var.data_plane_key != "" && !var.embed_nginx_agent_config ? 1 : 0

  metadata {
    name      = "nginx-agent-waf-config"
    namespace = var.namespace
  }

  data = {
    "nginx-agent.conf" = local.nginx_agent_waf_config
  }

  depends_on = [kubernetes_namespace.nginx]
}

# Deploy NGINX Plus Ingress Controller with NGINX One Agent
resource "helm_release" "nginx" {
  count            = var.enabled ? 1 : 0
  name             = "nginx-plus"
  repository       = var.helm_repository != "" ? var.helm_repository : null
  chart            = var.helm_chart
  namespace        = var.namespace
  create_namespace = false
  version          = var.chart_version
  force_update     = true
  recreate_pods    = true
  wait             = false
  timeout          = 600

  # Configure image pull secret for private registry (OCI chart)
  dynamic "set" {
    for_each = var.license_jwt != "" ? [1] : []
    content {
      name  = "controller.serviceAccount.imagePullSecretName"
      value = "regcred"
    }
  }

  # Configure NGINX Plus
  set {
    name  = "controller.nginxplus"
    value = "true"
  }

  # Use NGINX Plus image from the private registry
  set {
    name  = "controller.image.repository"
    value = local.controller_image_repository
  }

  set {
    name  = "controller.image.tag"
    value = local.controller_image_tag
  }

  dynamic "set" {
    for_each = var.enable_waf ? [1] : []
    content {
      name  = "controller.appprotect.enable"
      value = "true"
    }
  }

  dynamic "set" {
    for_each = var.enable_waf ? [1] : []
    content {
      name  = "controller.appprotect.v5"
      value = "true"
    }
  }

  # License JWT secret for NGINX Plus
  dynamic "set" {
    for_each = var.license_jwt != "" ? [1] : []
    content {
      name  = "controller.mgmt.licenseTokenSecretName"
      value = "nplus-license"
    }
  }

  # Configure NGINX One Agent
  dynamic "set" {
    for_each = var.data_plane_key != "" ? [1] : []
    content {
      name  = "nginxAgent.enable"
      value = var.enable_nginx_one_agent
    }
  }

  dynamic "set" {
    for_each = var.data_plane_key != "" ? [1] : []
    content {
      name  = "nginxAgent.dataplaneKeySecretName"
      value = "nginx-agent"
    }
  }

  dynamic "set" {
    for_each = var.data_plane_key != "" ? [1] : []
    content {
      name  = "nginxAgent.instanceGroup"
      value = "k8seks"
    }
  }

  dynamic "set" {
    for_each = var.data_plane_key != "" ? [1] : []
    content {
      name  = "nginxAgent.endpointHost"
      value = "agent.connect.nginx.com"
    }
  }

  dynamic "set" {
    for_each = var.data_plane_key != "" ? [1] : []
    content {
      name  = "nginxAgent.endpointPort"
      value = "443"
    }
  }

  dynamic "set" {
    for_each = var.data_plane_key != "" ? [1] : []
    content {
      name  = "nginxAgent.tlsSkipVerify"
      value = "false"
    }
  }

  dynamic "set" {
    for_each = var.data_plane_key != "" && var.enable_waf && !var.embed_nginx_agent_config ? [1] : []
    content {
      name  = "nginxAgent.customConfigMap"
      value = "nginx-agent-waf-config"
    }
  }

  set {
    name  = "controller.kind"
    value = "daemonset"
  }

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  dynamic "set" {
    for_each = local.service_annotations
    content {
      name  = "controller.service.annotations.${replace(set.key, ".", "\\.")}" 
      value = set.value
    }
  }

  dynamic "set" {
    for_each = var.enable_proxy_protocol ? [1] : []
    content {
      name  = "controller.config.proxy-protocol"
      value = "true"
    }
  }

  dynamic "set" {
    for_each = var.enable_proxy_protocol ? [1] : []
    content {
      name  = "controller.config.real-ip-header"
      value = "proxy_protocol"
    }
  }

  dynamic "set" {
    for_each = var.enable_proxy_protocol ? [1] : []
    content {
      name  = "controller.config.set-real-ip-from"
      value = "0.0.0.0/0"
    }
  }

  values = compact([var.helm_values, local.nginx_agent_values, local.waf_controller_values])

  depends_on = [
    kubernetes_namespace.nginx,
    kubernetes_secret.regcred,
    kubernetes_secret.nplus_license,
    kubernetes_secret.nginx_agent,
    kubernetes_config_map.nginx_agent_waf_config
  ]
}

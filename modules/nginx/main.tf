# This module deploys NGINX Plus with NGINX One Agent on the EKS cluster

locals {
  nginx_agent_values = var.data_plane_key != "" ? trimspace(<<-YAML
controller:
  volumes:
    - name: nginx-agent-state
      emptyDir: {}
    - name: nginx-agent-log
      emptyDir: {}
  volumeMounts:
    - name: nginx-agent-state
      mountPath: /var/lib/nginx-agent
    - name: nginx-agent-log
      mountPath: /var/log/nginx-agent
YAML
  ) : ""
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
    value = "private-registry.nginx.com/nginx-ic/nginx-plus-ingress"
  }

  set {
    name  = "controller.image.tag"
    value = var.nginx_plus_image_tag
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

  set {
    name  = "controller.kind"
    value = "daemonset"
  }

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  values = compact([var.helm_values, local.nginx_agent_values])

  depends_on = [
    kubernetes_namespace.nginx,
    kubernetes_secret.regcred,
    kubernetes_secret.nplus_license,
    kubernetes_secret.nginx_agent
  ]
}

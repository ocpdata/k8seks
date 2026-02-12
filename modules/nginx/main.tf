# This module deploys NGINX Plus with NGINX One Agent on the EKS cluster

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

# Create docker registry secret for NGINX Plus repository access
resource "kubernetes_secret" "nginx_registry" {
  count = var.enabled && var.nginx_repo_crt != "" && var.nginx_repo_key != "" ? 1 : 0

  metadata {
    name      = "nginx-repo"
    namespace = var.namespace
  }

  type = "kubernetes.io/dockercfg"

  data = {
    ".dockercfg" = jsonencode({
      "private-registry.nginx.com" = {
        "auth" = base64encode("${var.nginx_repo_crt}:${var.nginx_repo_key}")
      }
    })
  }

  depends_on = [kubernetes_namespace.nginx]
}

# Create secret for NGINX One Agent license
resource "kubernetes_secret" "nginx_license" {
  count = var.enabled && var.license_jwt != "" ? 1 : 0

  metadata {
    name      = "nginx-license"
    namespace = var.namespace
  }

  type = "Opaque"

  data = {
    "license.jwt" = var.license_jwt
  }

  depends_on = [kubernetes_namespace.nginx]
}

# Deploy NGINX Plus Ingress Controller with NGINX One Agent
resource "helm_release" "nginx" {
  count            = var.enabled ? 1 : 0
  name             = "nginx-plus"
  repository       = var.helm_repository
  chart            = var.helm_chart
  namespace        = var.namespace
  create_namespace = false
  version          = var.chart_version

  # Configure image pull secrets for private registry
  dynamic "set" {
    for_each = var.nginx_repo_crt != "" && var.nginx_repo_key != "" ? [1] : []
    content {
      name  = "controller.imagePullSecrets[0].name"
      value = "nginx-repo"
    }
  }

  # Configure NGINX Plus features
  set {
    name  = "controller.nginxPlus"
    value = "true"
  }

  set {
    name  = "controller.kind"
    value = "DaemonSet"
  }

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  # Configure NGINX One Agent if license provided
  dynamic "set" {
    for_each = var.license_jwt != "" ? [1] : []
    content {
      name  = "nginxOneAgent.enabled"
      value = var.enable_nginx_one_agent
    }
  }

  values = var.helm_values != "" ? [var.helm_values] : []

  depends_on = [
    kubernetes_namespace.nginx,
    kubernetes_secret.nginx_registry,
    kubernetes_secret.nginx_license
  ]
}

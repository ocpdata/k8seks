# This module deploys NGINX Plus on the EKS cluster
# Remove this file and replace with actual NGINX Plus Helm chart deployment

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

# Deploy NGINX Plus (placeholder - configure based on your needs)
resource "helm_release" "nginx" {
  count            = var.enabled ? 1 : 0
  name             = "nginx-plus"
  repository       = "https://helm.nginx.com/stable"
  chart            = "nginx-ingress"
  namespace        = var.namespace
  create_namespace = false
  version          = var.chart_version

  values = var.helm_values != "" ? [var.helm_values] : []

  depends_on = [kubernetes_namespace.nginx]
}

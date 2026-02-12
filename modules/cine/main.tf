resource "kubernetes_namespace" "cine" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace
  }
}

# Deployment for cine app
resource "kubernetes_deployment" "cine" {
  count = var.enabled ? 1 : 0

  metadata {
    name      = "cine"
    namespace = var.namespace
    labels = {
      app = "cine"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "cine"
      }
    }

    template {
      metadata {
        labels = {
          app = "cine"
        }
      }

      spec {
        container {
          name  = "cine"
          image = var.image

          command = length(var.command) > 0 ? var.command : null
          args    = length(var.args) > 0 ? var.args : null

          port {
            container_port = var.container_port
          }

          dynamic "env" {
            for_each = var.env
            content {
              name  = env.key
              value = env.value
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.cine]
}

# Service for cine app
resource "kubernetes_service" "cine" {
  count = var.enabled ? 1 : 0

  metadata {
    name      = "cine"
    namespace = var.namespace
  }

  spec {
    selector = {
      app = "cine"
    }

    port {
      port        = var.service_port
      target_port = var.container_port
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_namespace.cine]
}

resource "kubernetes_ingress_v1" "cine" {
  count = var.enabled && var.ingress_enabled ? 1 : 0

  metadata {
    name      = "cine"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class" = var.ingress_class_name
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.ingress_host

      http {
        path {
          path      = var.ingress_path
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.cine[0].metadata[0].name
              port {
                number = var.service_port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.cine]
}

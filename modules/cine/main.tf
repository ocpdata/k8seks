resource "kubernetes_namespace" "cine" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace
  }
}

locals {
  cine_command = length(var.command) > 0 ? var.command : (var.use_default_app ? ["node", "/app/server.js"] : null)
  cine_args    = length(var.args) > 0 ? var.args : null
}

# ConfigMap with the cine app
resource "kubernetes_config_map" "cine_app" {
  count = var.enabled && var.use_default_app ? 1 : 0

  metadata {
    name      = "cine-app"
    namespace = var.namespace
  }

  data = {
    "server.js" = file("${path.module}/app/server.js")
  }

  depends_on = [kubernetes_namespace.cine]
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

          command = local.cine_command
          args    = local.cine_args

          port {
            container_port = var.container_port
          }

          dynamic "env" {
            for_each = var.omdb_api_key != "" ? [1] : []
            content {
              name  = "OMDB_API_KEY"
              value = var.omdb_api_key
            }
          }

          dynamic "env" {
            for_each = var.env
            content {
              name  = env.key
              value = env.value
            }
          }

          dynamic "volume_mount" {
            for_each = var.use_default_app ? [1] : []
            content {
              name       = "cine-app"
              mount_path = "/app"
              read_only  = true
            }
          }
        }

        dynamic "volume" {
          for_each = var.use_default_app ? [1] : []
          content {
            name = "cine-app"
            config_map {
              name = kubernetes_config_map.cine_app[0].metadata[0].name
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.cine, kubernetes_config_map.cine_app]
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

output "namespace" {
  description = "Namespace where cine is deployed."
  value       = try(kubernetes_namespace.cine[0].metadata[0].name, null)
}

output "service_name" {
  description = "Service name for cine."
  value       = try(kubernetes_service.cine[0].metadata[0].name, null)
}

output "ingress_host" {
  description = "Ingress host for cine."
  value       = var.ingress_enabled ? var.ingress_host : null
}

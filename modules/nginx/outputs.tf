output "release_name" {
  description = "NGINX Plus Helm release name."
  value       = try(helm_release.nginx[0].name, null)
}

output "release_namespace" {
  description = "NGINX Plus Helm release namespace."
  value       = try(helm_release.nginx[0].namespace, null)
}

output "release_status" {
  description = "NGINX Plus Helm release status."
  value       = try(helm_release.nginx[0].status, null)
}

output "release_version" {
  description = "NGINX Plus Helm release version."
  value       = try(helm_release.nginx[0].version, null)
}

output "license_secret_name" {
  description = "Name of the Kubernetes secret containing NGINX Plus license JWT."
  value       = try(kubernetes_secret.nplus_license[0].metadata[0].name, null)
}

output "nginx_enabled" {
  description = "Whether NGINX Plus deployment is enabled."
  value       = var.enabled
}

output "nginx_one_agent_enabled" {
  description = "Whether NGINX One Agent is enabled."
  value       = var.enable_nginx_one_agent
}
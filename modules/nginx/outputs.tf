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

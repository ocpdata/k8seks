# ============================================================================
# EKS Cluster Outputs
# ============================================================================

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID."
  value       = module.eks.cluster_security_group_id
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.eks.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs."
  value       = module.eks.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs."
  value       = module.eks.public_subnets
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN for cluster."
  value       = module.eks.cluster_iam_role_arn
}

# ============================================================================
# NGINX Plus Outputs
# ============================================================================

output "nginx_release_name" {
  description = "NGINX Plus Helm release name."
  value       = try(module.nginx.release_name, null)
}

output "nginx_release_namespace" {
  description = "NGINX Plus Helm release namespace."
  value       = try(module.nginx.release_namespace, null)
}

output "nginx_release_status" {
  description = "NGINX Plus Helm release status."
  value       = try(module.nginx.release_status, null)
}

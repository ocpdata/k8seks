# ============================================================================
# Root Variables - EKS Core
# ============================================================================

variable "aws_region" {
  description = "AWS region for EKS."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_types" {
  description = "EC2 instance types for node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "min_size" {
  description = "Minimum number of nodes."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes."
  type        = number
  default     = 3
}

variable "desired_size" {
  description = "Desired number of nodes."
  type        = number
  default     = 2
}

# ============================================================================
# Root Variables - NGINX Plus Module
# ============================================================================

variable "enable_nginx" {
  description = "Enable NGINX Plus deployment."
  type        = bool
  default     = false
}

variable "nginx_namespace" {
  description = "Kubernetes namespace for NGINX Plus."
  type        = string
  default     = "nginx"
}

variable "nginx_chart_version" {
  description = "NGINX Ingress Controller Helm chart version."
  type        = string
  default     = "1.0.0"
}

variable "nginx_helm_values" {
  description = "Helm values for NGINX Plus deployment (YAML string)."
  type        = string
  default     = ""
}

# ============================================================================
# Root Variables - Tags
# ============================================================================

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

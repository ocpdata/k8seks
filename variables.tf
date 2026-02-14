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

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the EKS API endpoint."
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to the EKS API endpoint."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the EKS public endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
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
  default     = "2.4.3"
}

variable "nginx_helm_values" {
  description = "Helm values for NGINX Plus deployment (YAML string)."
  type        = string
  default     = ""
}

variable "nginx_repo_crt" {
  description = "NGINX repository certificate (from nginx-repo.crt)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "nginx_repo_key" {
  description = "NGINX repository key (from nginx-repo.key)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "license_jwt" {
  description = "NGINX One Agent license JWT token."
  type        = string
  default     = ""
  sensitive   = true
}

variable "data_plane_key" {
  description = "NGINX One Agent data plane API key."
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_nginx_one_agent" {
  description = "Enable NGINX One Agent for observability."
  type        = bool
  default     = true
}

variable "embed_nginx_agent_config" {
  description = "Embed NGINX Agent config in the controller image."
  type        = bool
  default     = true
}

variable "enable_nginx_waf" {
  description = "Enable F5 WAF for NGINX (App Protect v5)."
  type        = bool
  default     = false
}

variable "nginx_waf_image_tag" {
  description = "NGINX Plus Ingress Controller image tag when WAF is enabled."
  type        = string
  default     = "5.3.3"
}

variable "nginx_waf_image_repository" {
  description = "NGINX Plus Ingress Controller image repository when WAF is enabled."
  type        = string
  default     = "private-registry.nginx.com/nginx-ic-nap-v5/nginx-plus-ingress"
}

variable "enable_nginx_nlb" {
  description = "Enable NLB for the NGINX Ingress Controller service."
  type        = bool
  default     = false
}

variable "enable_nginx_proxy_protocol" {
  description = "Enable PROXY protocol settings for NGINX Ingress Controller."
  type        = bool
  default     = false
}

# ============================================================================
# Root Variables - Tags
# ============================================================================

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# ============================================================================
# Cine App Variables
# ============================================================================

variable "enable_cine" {
  description = "Enable or disable the cine module."
  type        = bool
  default     = false
}

variable "cine_namespace" {
  description = "Kubernetes namespace for cine."
  type        = string
  default     = "cine"
}

variable "cine_image" {
  description = "Docker image for cine."
  type        = string
  default     = "node:20-alpine"
}

variable "cine_replicas" {
  description = "Number of cine replicas."
  type        = number
  default     = 1
}

variable "cine_container_port" {
  description = "Container port for cine."
  type        = number
  default     = 3000
}

variable "cine_service_port" {
  description = "Service port for cine."
  type        = number
  default     = 80
}

variable "cine_command" {
  description = "Command to run in container."
  type        = list(string)
  default     = []
}

variable "cine_args" {
  description = "Arguments for the command."
  type        = list(string)
  default     = []
}

variable "cine_env" {
  description = "Environment variables for cine."
  type        = map(string)
  default     = {}
}

variable "omdb_api_key" {
  description = "OMDb API key for the cine app."
  type        = string
  default     = ""
  sensitive   = true
}

variable "cine_ingress_enabled" {
  description = "Enable Ingress for cine."
  type        = bool
  default     = true
}

variable "cine_ingress_host" {
  description = "Ingress host for cine."
  type        = string
  default     = "cine.example.com"
}

variable "cine_ingress_path" {
  description = "Ingress path for cine."
  type        = string
  default     = "/"
}

variable "cine_ingress_class_name" {
  description = "Ingress class name."
  type        = string
  default     = "nginx"
}

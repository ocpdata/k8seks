variable "enabled" {
  description = "Enable NGINX Plus deployment."
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace for NGINX Plus."
  type        = string
  default     = "nginx"
}

variable "helm_repository" {
  description = "NGINX Helm repository URL."
  type        = string
  default     = ""
}

variable "helm_chart" {
  description = "NGINX Helm chart name."
  type        = string
  default     = "oci://ghcr.io/nginx/charts/nginx-ingress"
}

variable "chart_version" {
  description = "NGINX Ingress Controller Helm chart version."
  type        = string
  default     = "2.4.3"
}

variable "nginx_plus_image_tag" {
  description = "NGINX Plus Ingress Controller image tag."
  type        = string
  default     = "5.3.3"
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

variable "enable_waf" {
  description = "Enable F5 WAF for NGINX (App Protect v5)."
  type        = bool
  default     = false
}

variable "waf_image_tag" {
  description = "NGINX Plus Ingress Controller image tag when WAF is enabled."
  type        = string
  default     = "5.3.3"
}

variable "helm_values" {
  description = "Additional Helm values for NGINX deployment (YAML string)."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}

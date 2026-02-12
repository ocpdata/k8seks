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

variable "chart_version" {
  description = "NGINX Ingress Controller Helm chart version."
  type        = string
  default     = "1.0.0"
}

variable "helm_values" {
  description = "Helm values for NGINX Plus deployment (YAML string)."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}

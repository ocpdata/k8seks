variable "enabled" {
  description = "Enable or disable the cine module."
  type        = bool
  default     = false
}

variable "namespace" {
  description = "Kubernetes namespace for cine."
  type        = string
  default     = "cine"
}

variable "image" {
  description = "Docker image for cine."
  type        = string
  default     = "node:20-alpine"
}

variable "replicas" {
  description = "Number of cine replicas."
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Container port for cine."
  type        = number
  default     = 3000
}

variable "service_port" {
  description = "Service port for cine."
  type        = number
  default     = 80
}

variable "command" {
  description = "Command to run in container."
  type        = list(string)
  default     = []
}

variable "args" {
  description = "Arguments for the command."
  type        = list(string)
  default     = []
}

variable "env" {
  description = "Environment variables for cine."
  type        = map(string)
  default     = {}
}

variable "omdb_api_key" {
  description = "OMDb API key for cine app."
  type        = string
  default     = ""
  sensitive   = true
}

variable "use_default_app" {
  description = "Use the default cine app bundled with this module."
  type        = bool
  default     = true
}

variable "ingress_enabled" {
  description = "Enable Ingress for cine."
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Ingress host for cine."
  type        = string
  default     = "cine.example.com"
}

variable "ingress_path" {
  description = "Ingress path for cine."
  type        = string
  default     = "/"
}

variable "ingress_class_name" {
  description = "Ingress class name."
  type        = string
  default     = "nginx"
}

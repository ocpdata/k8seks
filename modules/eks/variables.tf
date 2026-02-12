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

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

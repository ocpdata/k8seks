# EKS Cluster Module
module "eks" {
  source = "./modules/eks"

  aws_region         = var.aws_region
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_cidr           = var.vpc_cidr
  instance_types     = var.instance_types
  min_size           = var.min_size
  max_size           = var.max_size
  desired_size       = var.desired_size

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  tags = var.tags
}

# NGINX Plus Module (optional)
module "nginx" {
  source = "./modules/nginx"

  enabled                  = var.enable_nginx
  namespace                = var.nginx_namespace
  chart_version            = var.nginx_chart_version
  helm_values              = var.nginx_helm_values
  nginx_repo_crt           = var.nginx_repo_crt
  nginx_repo_key           = var.nginx_repo_key
  license_jwt              = var.license_jwt
  data_plane_key           = var.data_plane_key
  enable_nginx_one_agent   = var.enable_nginx_one_agent
  enable_waf               = var.enable_nginx_waf
  waf_image_tag            = var.nginx_waf_image_tag

  tags = var.tags

  depends_on = [module.eks]
}

# Cine App Module (optional)
module "cine" {
  source = "./modules/cine"

  enabled            = var.enable_cine
  namespace          = var.cine_namespace
  image              = var.cine_image
  replicas           = var.cine_replicas
  container_port     = var.cine_container_port
  service_port       = var.cine_service_port
  command            = var.cine_command
  args               = var.cine_args
  env                = var.cine_env
  omdb_api_key        = var.omdb_api_key
  ingress_enabled    = var.cine_ingress_enabled
  ingress_host       = var.cine_ingress_host
  ingress_path       = var.cine_ingress_path
  ingress_class_name = var.cine_ingress_class_name

  depends_on = [module.eks]
}


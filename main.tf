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

  tags = var.tags

  depends_on = [module.eks]
}


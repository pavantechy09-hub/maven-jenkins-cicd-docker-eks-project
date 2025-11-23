# module "ec2" {
#   source = "./modules/ec2"

#   aws_region     = var.aws_region
#   instance_type  = var.instance_type
#   key_name       = var.key_name
#   allowed_ip_cidr = var.allowed_ip_cidr
#   repo_url       = var.repo_url
#   repo_branch    = var.repo_branch
#   tomcat_version = var.tomcat_version
#   use_docker_deploy = var.use_docker_deploy
#   docker_image_repo = var.docker_image_repo
#   docker_image_tag  = var.docker_image_tag
# }

module "ec2" {
  source = "./modules/ec2"

  aws_region        = var.aws_region
  instance_type     = var.instance_type
  key_name          = var.key_name
  allowed_ip_cidr   = var.allowed_ip_cidr
  repo_url          = var.repo_url
  repo_branch       = var.repo_branch
  tomcat_version    = var.tomcat_version
  use_docker_deploy = var.use_docker_deploy
  docker_image_repo = var.docker_image_repo
  docker_image_tag  = var.docker_image_tag
}
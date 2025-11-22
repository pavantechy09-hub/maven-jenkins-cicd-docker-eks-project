variable "aws_region" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "allowed_ip_cidr" {
  type = string
}

variable "repo_url" {
  type = string
}

variable "repo_branch" {
  type = string
}

variable "tomcat_version" {
  type = string
}

variable "use_docker_deploy" {
  type    = bool
  default = false
}

variable "docker_image_repo" {
  type    = string
  default = ""
}

variable "docker_image_tag" {
  type    = string
  default = "latest"
}

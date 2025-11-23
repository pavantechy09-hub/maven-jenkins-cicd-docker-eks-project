variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of an existing AWS key pair to enable SSH access"
  type        = string
}

variable "allowed_ip_cidr" {
  description = "CIDR block allowed to access instance (SSH/Tomcat). Set to 0.0.0.0/0 for testing"
  type        = string
  default     = "0.0.0.0/0"
}

variable "repo_url" {
  description = "Git clone URL for the application repository"
  type        = string
  default     = ""
}

variable "repo_branch" {
  description = "Branch to checkout when cloning the repo"
  type        = string
  default     = "main"
}

variable "tomcat_version" {
  description = "Tomcat version to install"
  type        = string
  default     = "9.0.68"
}

# Docker deployment options: when true the EC2 will pull and run the Docker image
variable "use_docker_deploy" {
  description = "If true, user-data will install Docker and pull/run the image specified by docker_image_repo"
  type        = bool
  default     = false
}

variable "docker_image_repo" {
  description = "Repository for the Docker image (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp)"
  type        = string
  default     = ""
}

variable "docker_image_tag" {
  description = "Tag for the Docker image to pull/run"
  type        = string
  default     = "latest"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "app-instance-sg"
  description = "Allow SSH and Tomcat"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip_cidr]
  }

  ingress {
    description = "Tomcat HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  associate_public_ip_address = true
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = templatefile("${path.module}/user_data.tpl", {
    repo_url           = var.repo_url
    repo_branch        = var.repo_branch
    tomcat_version     = var.tomcat_version
    use_docker_deploy  = var.use_docker_deploy
    docker_image_repo  = var.docker_image_repo
    docker_image_tag   = var.docker_image_tag
    APP_DIR            = "/home/ec2-user/app"
  })

  tags = {
    Name = "maven-java-app"
  }
}

// ...existing code...

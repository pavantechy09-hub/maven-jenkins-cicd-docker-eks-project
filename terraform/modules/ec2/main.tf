data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_availability_zones" "available" {}

// If user didn't provide a VPC/subnet, create a minimal VPC and public subnet
resource "aws_vpc" "this" {
  count             = var.vpc_id == "" ? 1 : 0
  cidr_block        = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "maven-app-vpc"
  }
}

resource "aws_subnet" "this" {
  count                   = var.subnet_id == "" ? 1 : 0
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "maven-app-subnet"
  }
}

resource "aws_internet_gateway" "this" {
  count  = var.vpc_id == "" ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  tags = {
    Name = "maven-app-igw"
  }
}

resource "aws_route_table" "public" {
  count  = var.vpc_id == "" ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }
}

resource "aws_route_table_association" "public" {
  count          = var.vpc_id == "" ? 1 : 0
  subnet_id      = aws_subnet.this[0].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_security_group" "instance_sg" {
  name        = "app-instance-sg"
  description = "Allow SSH and Tomcat"
  vpc_id      = var.vpc_id != "" ? var.vpc_id : aws_vpc.this[0].id

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

  ingress {
    description = "Jenkins UI"
    from_port   = var.jenkins_port
    to_port     = var.jenkins_port
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
  subnet_id              = var.subnet_id != "" ? var.subnet_id : aws_subnet.this[0].id

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

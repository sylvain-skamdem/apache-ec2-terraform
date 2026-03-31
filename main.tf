###############################################################
# main.tf – Deploy Apache Web Server on EC2 using User Data
###############################################################

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

###############################################################
# Data Source – Latest Amazon Linux 2 AMI
###############################################################
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

###############################################################
# Security Group – Allow SSH (22) and HTTP (80)
###############################################################
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebServerSG"
  }
}

###############################################################
# EC2 Instance
###############################################################
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    # Update packages
    yum update -y

    # Install Apache
    yum install -y httpd

    # Set hostname
    hostnamectl set-hostname Myfirstwebserver

    # Create custom index page
    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
      <head>
        <title>Myfirstwebserver</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; margin-top: 100px; background-color: #f0f4f8; }
          h1   { color: #232f3e; font-size: 2.5em; }
          p    { color: #555; }
        </style>
      </head>
      <body>
        <h1>Hello from Myfirstwebserver</h1>
        <p>Deployed automatically By Sylvain via Terraform &amp; EC2 User Data</p>
      </body>
    </html>
    HTML

    # Enable and start Apache
    systemctl enable httpd
    systemctl start httpd
  EOF

  tags = {
    Name        = "Myfirstwebserver"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

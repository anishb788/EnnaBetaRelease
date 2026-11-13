terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # You can change this to your preferred region (e.g., us-west-2)
}

# Security Group to allow HTTP (80/5000) and SSH (22)
resource "aws_security_group" "enna_sg" {
  name        = "enna-sg"
  description = "Allow inbound traffic for Enna app"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Recommendation: Restrict to your IP in production
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Free-tier eligible Ubuntu EC2 Instance
resource "aws_instance" "enna_server" {
  ami           = "ami-04a81a99f5ec58529" # Ubuntu 22.04 LTS (us-east-1)
  instance_type = "t2.micro"              # Free tier eligible
  security_groups = [aws_security_group.enna_sg.name]

  tags = {
    Name = "EnnaBudgetApp"
  }
}

output "instance_public_ip" {
  value = aws_instance.enna_server.public_ip
}

# Create an SSH key pair for EC2 access (Terraform can generate one for you)
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "enna_auth" {
  key_name   = "enna-key"
  public_key = tls_private_key.rsa_key.public_key_openssh
}

# Output your private key so you can save it for GitHub Secrets
output "private_key" {
  value     = tls_private_key.rsa_key.private_key_pem
  sensitive = true
}

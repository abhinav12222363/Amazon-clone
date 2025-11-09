# -------------------------------
# Terraform Configuration for Amazon Clone Deployment
# -------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.20.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # ✅ Your AWS Region (N. Virginia)
}

# -------------------------------
# Create SSH Key Pair in AWS
# -------------------------------
resource "aws_key_pair" "amazon_key" {
  key_name   = "amazon-clone-key"
  public_key = file("C:/Users/HP/.ssh/id_rsa.pub")  # ✅ Use your exact Windows path
}

# -------------------------------
# Create Security Group
# -------------------------------
resource "aws_security_group" "amazon_clone_sg" {
  name_prefix = "amazon-clone-sg"

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
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

# -------------------------------
# Create EC2 Instance
# -------------------------------
resource "aws_instance" "amazon_clone_ec2" {
  ami           = "ami-0ecb62995f68bb549"  # ✅ Ubuntu 22.04 for us-east-1
  instance_type = "t2.micro"               # ✅ Free Tier eligible
  key_name      = aws_key_pair.amazon_key.key_name
  security_groups = [aws_security_group.amazon_clone_sg.name]

  tags = {
    Name = "AmazonCloneEC2"
  }

  # Save EC2 IP to Ansible hosts file
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > ../ansible/hosts"
  }
}

# -------------------------------
# Output EC2 Public IP
# -------------------------------
output "instance_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.amazon_clone_ec2.public_ip
}

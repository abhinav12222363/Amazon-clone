terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ---------------------------
# VPC + Internet Setup
# ---------------------------
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "main-gw"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------------------
# Security Group
# ---------------------------
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main_vpc.id
  name   = "web-sg"

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

  ingress {
    description = "Allow NRPE (Nagios)"
    from_port   = 5666
    to_port     = 5666
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
    Name = "web-sg"
  }
}

# ---------------------------
# EC2 Instance - Amazon Clone (Frontend App)
# ---------------------------
resource "aws_instance" "amazon_clone" {
  ami                    = "ami-0ecb62995f68bb549"  # Ubuntu 24.04 LTS
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "ec2-key-pair"  # Replace with your key name

  user_data = <<-EOT
    #!/bin/bash
    set -e
    sudo apt update -y
    sudo apt install -y nginx git nodejs npm nagios-nrpe-server nagios-plugins-basic

    cd /var/www
    sudo rm -rf html
    sudo git clone -b master https://github.com/abhinav12222363/Amazon-clone.git
    sudo mv Amazon-clone html

    # Allow Nagios to monitor this instance
    sudo sed -i 's/^allowed_hosts=.*/allowed_hosts=0.0.0.0/' /etc/nagios/nrpe.cfg
    sudo systemctl restart nagios-nrpe-server
    sudo systemctl enable nginx
    sudo systemctl restart nginx
  EOT

  tags = {
    Name = "AmazonClone"
  }
}

# ---------------------------
# EC2 Instance - Nagios Server (Monitoring)
# ---------------------------
resource "aws_instance" "nagios_server" {
  ami                    = "ami-0ecb62995f68bb549"  # Ubuntu 24.04 LTS
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "ec2-key-pair"

  user_data = <<-EOT
    #!/bin/bash
    set -e

    # Install Apache, Nagios, and plugins
    sudo apt update -y
    sudo apt install -y apache2 nagios4 nagios-plugins nagios-nrpe-plugin apache2-utils

    # Create Nagios web user (admin: nagios)
    sudo htpasswd -bc /etc/nagios4/htpasswd.users nagiosadmin nagios

    # Fix Apache alias path for Ubuntu 24.04 (htdocs)
    sudo sed -i 's|/usr/share/nagios4/html|/usr/share/nagios4/htdocs|g' /etc/nagios4/apache2.conf

    # Ensure directory permissions
    sudo chown -R www-data:www-data /usr/share/nagios4/htdocs
    sudo chmod -R 755 /usr/share/nagios4/htdocs
    sudo chmod 644 /etc/nagios4/htpasswd.users

    # Add directory access rules (fix Forbidden error)
    echo '<Directory "/usr/share/nagios4/htdocs">
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
        AuthUserFile /etc/nagios4/htpasswd.users
        AuthName "Nagios Access"
        AuthType Basic
    </Directory>' | sudo tee /etc/apache2/conf-available/nagios4-access.conf

    sudo a2enconf nagios4-access
    sudo systemctl reload apache2

    # Configure Nagios to monitor Amazon Clone EC2
    cat <<EOF | sudo tee /etc/nagios4/conf.d/amazon-clone.cfg
define host {
    use                     linux-server
    host_name               amazon-clone-ec2
    alias                   Amazon Clone EC2
    address                 ${aws_instance.amazon_clone.private_ip}
    max_check_attempts      5
    check_period            24x7
    notification_interval   30
    notification_period     24x7
}

define service {
    use                             generic-service
    host_name                       amazon-clone-ec2
    service_description             PING
    check_command                   check_ping!100.0,20%!500.0,60%
}

define service {
    use                             generic-service
    host_name                       amazon-clone-ec2
    service_description             HTTP
    check_command                   check_http
}

define service {
    use                             generic-service
    host_name                       amazon-clone-ec2
    service_description             NRPE Load
    check_command                   check_nrpe!check_load
}
EOF

    # Restart services
    sudo systemctl enable apache2
    sudo systemctl restart apache2
    sudo systemctl enable nagios4
    sudo systemctl restart nagios4
  EOT

  tags = {
    Name = "NagiosServer"
  }
}

# ---------------------------
# Outputs
# ---------------------------
output "amazon_clone_ip" {
  value = aws_instance.amazon_clone.public_ip
}

output "nagios_ip" {
  value = aws_instance.nagios_server.public_ip
}

output "amazon_clone_url" {
  value = "http://${aws_instance.amazon_clone.public_ip}"
}

output "nagios_dashboard_url" {
  value = "http://${aws_instance.nagios_server.public_ip}/nagios4"
}

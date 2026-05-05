terraform {
  required_version = ">= 1.5.0"

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

locals {
  public_subnet_count = 2
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  count = local.public_subnet_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = local.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow public access to the API"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP API"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_app_cidr_blocks
  }

  ingress {
    description = "HTTP analytics API"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = var.allowed_app_cidr_blocks
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Allow PostgreSQL only from the EC2 security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow PostgreSQL only from the EC2 security group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.project_name}-postgres"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = var.db_instance_class
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  apply_immediately      = true
  publicly_accessible    = false
  skip_final_snapshot    = true

  lifecycle {
    ignore_changes = [engine_version]
  }

  tags = {
    Name = "${var.project_name}-postgres"
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    DEBUG_LOG="/home/ec2-user/debug.log"
    touch "$DEBUG_LOG"
    chown ec2-user:ec2-user "$DEBUG_LOG"
    exec > >(tee -a /var/log/user-data.log "$DEBUG_LOG") 2>&1

    echo "===== user_data started at $(date -Is) ====="
    echo "Container image: ${var.container_image}"

    sudo dnf update -y
    sudo dnf install -y docker
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ec2-user || true

    for i in {1..30}; do
      if sudo systemctl is-active --quiet docker; then
        echo "Docker service is active"
        break
      fi

      echo "Waiting for Docker service..."
      sleep 2
    done

    sudo docker --version

    sudo docker pull ${var.container_image}
    sudo docker rm -f volleyball-api volleyball-analytics || true
    sudo docker run -d \
      --name volleyball-api \
      --restart unless-stopped \
      -p 3000:3000 \
      -e NODE_ENV=production \
      -e SERVICE_LABEL="Volleyball Match Service running" \
      -e PORT=3000 \
      -e DB_HOST=${aws_db_instance.postgres.address} \
      -e DB_USER=${var.db_username} \
      -e DB_PASSWORD=${var.db_password} \
      -e DB_NAME=${var.db_name} \
      -e DB_PORT=5432 \
      ${var.container_image}

    sudo docker run -d \
      --name volleyball-analytics \
      --restart unless-stopped \
      -p 3001:3001 \
      -e NODE_ENV=production \
      -e SERVICE_LABEL="Volleyball Analytics Service running" \
      -e PORT=3001 \
      -e DB_HOST=${aws_db_instance.postgres.address} \
      -e DB_USER=${var.db_username} \
      -e DB_PASSWORD=${var.db_password} \
      -e DB_NAME=${var.db_name} \
      -e DB_PORT=5432 \
      ${var.container_image} npm run start:analytics

    sleep 10

    {
      echo "===== docker ps -a ====="
      sudo docker ps -a
      echo
      echo "===== docker logs volleyball-api ====="
      sudo docker logs volleyball-api || true
      echo
      echo "===== docker logs volleyball-analytics ====="
      sudo docker logs volleyball-analytics || true
      echo
      echo "===== listening ports ====="
      sudo ss -tulpen | grep -E ':3000|:3001' || true
      echo
      echo "===== local match service /info test ====="
      curl -sS -m 5 http://localhost:3000/info || true
      echo
      echo "===== local analytics service /info test ====="
      curl -sS -m 5 http://localhost:3001/info || true
      echo
      echo "===== user_data finished at $(date -Is) ====="
    } >> "$DEBUG_LOG" 2>&1

    chown ec2-user:ec2-user "$DEBUG_LOG"
  EOF

  tags = {
    Name = "${var.project_name}-app"
  }
}

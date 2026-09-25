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

variable "aws_region" {
  description = "Target AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

# 1. VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "enterprise-3tier-vpc"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "enterprise-3tier-igw"
  }
}

# 3. Public Subnets (Ingress / ALB Tier) - Multi-AZ
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "3tier-public-1a"
    Tier = "Public"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = true

  tags = {
    Name = "3tier-public-1c"
    Tier = "Public"
  }
}

# 4. Private Subnets (Application Tier) - Multi-AZ
resource "aws_subnet" "private_ap_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "3tier-private-ap-1a"
    Tier = "Application"
  }
}

resource "aws_subnet" "private_ap_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "3tier-private-ap-1c"
    Tier = "Application"
  }
}

# 5. Isolated Subnets (Database Tier) - Multi-AZ
resource "aws_subnet" "isolated_db_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "3tier-isolated-db-1a"
    Tier = "Database"
  }
}

resource "aws_subnet" "isolated_db_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "3tier-isolated-db-1c"
    Tier = "Database"
  }
}

# 6. Route Tables & Associations
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "3tier-public-rt"
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

# DB層は外部ルートを持たない完全分離ルートテーブル
resource "aws_route_table" "isolated_db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "3tier-isolated-db-rt"
  }
}

resource "aws_route_table_association" "db_1a" {
  subnet_id      = aws_subnet.isolated_db_1a.id
  route_table_id = aws_route_table.isolated_db.id
}

resource "aws_route_table_association" "db_1c" {
  subnet_id      = aws_subnet.isolated_db_1c.id
  route_table_id = aws_route_table.isolated_db.id
}

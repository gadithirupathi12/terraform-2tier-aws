# main.tf — Core networking infrastructure

# ── Terraform Backend (STATE STORAGE) ────────────────────────────────
terraform {
  backend "s3" {
    bucket = "terraform-buucket09823"
    key    = "aws-2tier/terraform.tfstate"
    region = "ap-south-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ── Provider: tells Terraform to use AWS ─────────────────────────────
provider "aws" {
  region = var.aws_region
}

# ── VPC ───────────────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "MyAppVPC" }
}

# ── Public Subnet (EC2) ───────────────────────────────────────────────────
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "PublicSubnet" }
}

# ── Private Subnet 1 (RDS) ────────────────────────────────────────────────
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "PrivateSubnet-1" }
}

# ── Private Subnet 2 (RDS multi-AZ) ─────────────────────────────────────
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "PrivateSubnet-2" }
}

# ── Internet Gateway ──────────────────────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "MyAppIGW" }
}

# ── Public Route Table ────────────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "PublicRouteTable" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── Outputs ───────────────────────────────────────────────────────────────
output "vpc_id" { value = aws_vpc.main.id }
output "public_subnet" { value = aws_subnet.public.id }
output "private_subnet_1" { value = aws_subnet.private_1.id }

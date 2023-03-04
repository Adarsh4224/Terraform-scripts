provider "aws" {
  region = var.region
}

resource "aws_vpc" "example" {
  cidr_block = var.vpc_cidr_block
}

module "public_subnet" {
  source = "./subnet"
  name   = "public"
  cidr   = var.public_subnet_cidr
  az     = var.public_subnet_az
  vpc_id = aws_vpc.example.id
}

module "private_subnet" {
  source = "./subnet"
  name   = "private"
  cidr   = var.private_subnet_cidr
  az     = var.private_subnet_az
  vpc_id = aws_vpc.example.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = module.public_subnet.subnet_id
  route_table_id = aws_route_table.public.id
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id = module.public_subnet.subnet_id
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id = module.private_subnet.subnet_id
  route_table_id = aws_route_table.private.id
}

module "ec2_instance" {
  source               = "./ec2"
  instance_name_prefix = var.instance_name_prefix
  instance_count       = var.instance_count
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  public_ip            = false
  subnet_id            = module.private_subnet.subnet_id
}

output "nat_public_ip" {
  value = aws_eip.nat.public_ip
}

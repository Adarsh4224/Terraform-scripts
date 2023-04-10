provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

module "public_subnet" {
  source = "./subnet"
  name   = "public"
  cidr   = "10.0.1.0/24"
  az     = "us-west-2a"
  vpc_id = aws_vpc.example.id
}

module "private_subnet" {
  source = "./subnet"
  name   = "private"
  cidr   = "10.0.2.0/24"
  az     = "us-west-2b"
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
  subnet_id      = module.public_subnet.subnet_id
  route_table_id = aws_route_table.public.id
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = module.public_subnet.subnet_id
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = module.private_subnet.subnet_id
  route_table_id = aws_route_table.private.id
}

module "ec2_instance" {
  source               = "./ec2"
  instance_name_prefix = "example-instance"
  instance_count       = 2
  ami_id               = "ami-0c55b159cbfafe1f0"
  instance_type        = "t2.micro"
  key_name             = "example-key"
  public_ip            = false
  subnet_id            = module.private_subnet.subnet_id
}

output "nat_public_ip" {
  value = aws_eip.nat.public_ip
}

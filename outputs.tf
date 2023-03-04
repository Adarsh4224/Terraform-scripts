output "vpc_id" {
  value = aws_vpc.example.id
}

output "public_subnet_id" {
  value = module.public_subnet.subnet_id
}

output "private_subnet_id" {
  value = module.private_subnet.subnet_id
}

output "ec2_instance_private_ips" {
  value = module.ec2_instance.private_ips
}

output "ec2_instance_public_ips" {
  value = module.ec2_instance.public_ips
}

output "nat_public_ip" {
  value = aws_eip.nat.public_ip
}


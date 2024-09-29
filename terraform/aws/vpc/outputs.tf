output "zona_a_vpc_id" {
  value = aws_vpc.zona_a_vpc.id
}

output "zona_b_vpc_id" {
  value = aws_vpc.zona_b_vpc.id
}

output "public_subnet_zona_a_id" {
  value = aws_subnet.public_subnet_zona_a.id
}

output "public_subnet_zona_b_id" {
  value = aws_subnet.public_subnet_zona_b.id
}

variable "ami_id_zona_a" {
  description = "AMI ID para as instâncias EC2 us-east-1"
  default     = "ami-0ebfd941bbafe70c6" 
}

variable "ami_id_zona_b" {
  description = "AMI ID para as instâncias EC2 us-west-2"
  default     = "ami-08d8ac128e0a1b91c" 
}
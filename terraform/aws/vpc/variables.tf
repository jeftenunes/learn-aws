variable "region_zona_a" {
  description = "Region zona A"
  default     = "us-east-1"
}

variable "region_zona_b" {
  description = "Region zona B"
  default     = "us-west-2"
}

variable "az_A" {
  description = "Zona A"
  default     = "us-east-1a"
}

variable "az_B" {
  description = "Zona B"
  default     = "us-west-2b"
}

variable "vpc_cidr_block_zona_a" {
  default = "10.0.0.0/16"
}

variable "vpc_cidr_block_zona_b" {
  default = "10.1.0.0/16"
}

variable "public_subnet_cidr_zona_a" {
  default = "10.0.1.0/24"
}

variable "public_subnet_cidr_zona_b" {
  default = "10.1.1.0/24"
}

variable "private_subnets_zona_a" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "private_subnets_zona_b" {
  default = ["10.1.3.0/24", "10.1.4.0/24"]
}

output "instance_id_zona_a" {
  value = aws_instance.bia_zona_a.id
}

output "instance_id_zona_b" {
  value = aws_instance.bia_zona_b.id
}

variable "git_repo" {
  default     = "https://github.com/henrylle/bia.git"
  description = "Repositório Git com a aplicação Node.js"
}

variable "app_name" {
  default     = "bia_dev"
  description = "Nome do diretório da aplicação Node.js"
}
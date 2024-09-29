terraform {
  required_providers{
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.69"
    }
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "ssm-role"

 assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_vpc" "zona_a_vpc" {
  enable_dns_support   = true
  enable_dns_hostnames = true
  provider             = aws.zona_a
  cidr_block           = var.vpc_cidr_block_zona_a
}

resource "aws_vpc" "zona_b_vpc" {
  enable_dns_support   = true
  enable_dns_hostnames = true
  provider             = aws.zona_b
  cidr_block           = var.vpc_cidr_block_zona_b
}

resource "aws_subnet" "public_subnet_zona_a" {
  provider          = aws.zona_a
  vpc_id            = aws_vpc.zona_a_vpc.id
  cidr_block        = var.public_subnet_cidr_zona_a
  availability_zone = var.az_A
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_zona_b" {
  provider          = aws.zona_b
  vpc_id            = aws_vpc.zona_b_vpc.id
  cidr_block        = var.public_subnet_cidr_zona_b
  availability_zone = var.az_B
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw_zona_a" {
  provider = aws.zona_a
  vpc_id   = aws_vpc.zona_a_vpc.id

  tags = {
    Name = "igw_zona_a"
  }
}

resource "aws_internet_gateway" "igw_zona_b" {
  provider = aws.zona_b
  vpc_id   = aws_vpc.zona_b_vpc.id

  tags = {
    Name = "igw_zona_b"
  }
}

resource "aws_route_table" "public_rt_zona_a" {
  provider = aws.zona_a
  vpc_id   = aws_vpc.zona_a_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_zona_a.id
  }

  tags = {
    Name = "public_rt_us_zona_a"
  }
}

resource "aws_route_table_association" "public_rt_assoc_zona_a" {
  provider       = aws.zona_a
  subnet_id      = aws_subnet.public_subnet_zona_a.id
  route_table_id = aws_route_table.public_rt_zona_a.id
}

resource "aws_route_table" "public_rt_zona_b" {
  provider = aws.zona_b
  vpc_id   = aws_vpc.zona_b_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_zona_b.id
  }

  tags = {
    Name = "public_rt_us_zona_b"
  }
}

resource "aws_route_table_association" "public_rt_assoc_zona_b" {
  provider       = aws.zona_b
  subnet_id      = aws_subnet.public_subnet_zona_b.id
  route_table_id = aws_route_table.public_rt_zona_b.id
}

resource "aws_security_group" "allow_traffic_zona_a" {
  provider = aws.zona_a
  vpc_id   = aws_vpc.zona_a_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = []
  }

 egress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_traffic_zona_b" {
  provider = aws.zona_b
  vpc_id   = aws_vpc.zona_b_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = []
  }

 egress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bia_zona_a" {
  provider               = aws.zona_a
  instance_type          = "t3.micro"
  ami                    = var.ami_id_zona_a
  subnet_id              = aws_subnet.public_subnet_zona_a.id
  vpc_security_group_ids = [aws_security_group.allow_traffic_zona_a.id]

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y git curl

              if ! command -v amazon-ssm-agent &> /dev/null; then
                  echo "Instalando o SSM Agent..."
                  sudo snap install amazon-ssm-agent --classic
              fi

              sudo systemctl start amazon-ssm-agent
              sudo systemctl enable amazon-ssm-agent

              EOF
}

resource "aws_instance" "bia_zona_b" {
  provider               = aws.zona_b
  instance_type          = "t3.micro"
  ami                    = var.ami_id_zona_b
  subnet_id              = aws_subnet.public_subnet_zona_b.id
  vpc_security_group_ids = [aws_security_group.allow_traffic_zona_b.id]

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y git curl

              if ! command -v amazon-ssm-agent &> /dev/null; then
                  echo "Instalando o SSM Agent..."
                  sudo snap install amazon-ssm-agent --classic
              fi

              sudo systemctl start amazon-ssm-agent
              sudo systemctl enable amazon-ssm-agent

              EOF
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
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
  provider                = aws.zona_a
  vpc_id                  = aws_vpc.zona_a_vpc.id
  cidr_block              = var.public_subnet_cidr_zona_a
  availability_zone       = var.az_A
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_zona_b" {
  provider                = aws.zona_b
  vpc_id                  = aws_vpc.zona_b_vpc.id
  cidr_block              = var.public_subnet_cidr_zona_b
  availability_zone       = var.az_B
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet_zona_a" {
  provider          = aws.zona_a
  count             = length(var.private_subnets_zona_a)
  vpc_id            = aws_vpc.zona_a_vpc.id
  cidr_block        = element(var.private_subnets_zona_a, count.index)
  availability_zone = var.az_A

  tags = {
    Name = "private_subnets_zona_a_${count.index}"
  }
}

resource "aws_subnet" "private_subnet_zona_b" {
  provider          = aws.zona_b
  count             = length(var.private_subnets_zona_b)
  vpc_id            = aws_vpc.zona_b_vpc.id
  cidr_block        = element(var.private_subnets_zona_b, count.index)
  availability_zone = var.az_B

  tags = {
    Name = "private_subnets_zona_b_${count.index}"
  }
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
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow traffic on all ports and ip ranges"
  }
}

resource "aws_security_group" "allow_traffic_zona_b" {
  provider = aws.zona_b
  vpc_id   = aws_vpc.zona_b_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow traffic on all ports and ip ranges"
  }
}

resource "aws_instance" "bia_zona_a" {
  provider                    = aws.zona_a
  instance_type               = "t3.micro"
  ami                         = var.ami_id_zona_a
  subnet_id                   = aws_subnet.public_subnet_zona_a.id
  vpc_security_group_ids      = [aws_security_group.allow_traffic_zona_a.id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash

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

              if ! command -v amazon-ssm-agent &> /dev/null; then
                  echo "Instalando o SSM Agent..."
                  sudo snap install amazon-ssm-agent --classic
              fi

              sudo systemctl start amazon-ssm-agent
              sudo systemctl enable amazon-ssm-agent

              EOF
}

resource "aws_vpc_endpoint" "vpc_ssm_vpce_zona_a" {
  vpc_id              = aws_vpc.zona_a_vpc.id
  service_name        = "com.amazonaws.${var.region_zona_a}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.public_subnet_zona_a.id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.allow_traffic_zona_a.id]
}

resource "aws_vpc_endpoint" "vpc_ec2messages_vpce" {
  vpc_id              = aws_vpc.zona_a_vpc.id
  service_name        = "com.amazonaws.${var.region_zona_a}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.public_subnet_zona_a.id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.allow_traffic_zona_a.id]
}

resource "aws_vpc_endpoint" "vpc_ssmmessages_vpce" {
  vpc_id              = aws_vpc.zona_a_vpc.id
  service_name        = "com.amazonaws.${var.region_zona_a}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.public_subnet_zona_a.id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.allow_traffic_zona_a.id]
}

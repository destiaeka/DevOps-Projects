terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  cidr_block       = "172.29.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc"
  }
}


resource "aws_subnet" "pub_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "172.29.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "public_a"
  }
}

resource "aws_subnet" "pub_b" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "172.29.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "public_b"
  }
}

resource "aws_subnet" "priv_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "172.29.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_a"
  }
}

resource "aws_subnet" "priv_b" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "172.29.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private_b"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_eip" "eip" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pub_a.id

  tags = {
    Name = "ngw"
  }
}

resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt_public"
  }
}

resource "aws_route_table" "rt_private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "rt_private"
  }
}

resource "aws_route_table_association" "rt_pub_a" {
  subnet_id      = aws_subnet.pub_a.id
  route_table_id = aws_route_table.rt_public.id
}

resource "aws_route_table_association" "rt_pub_b" {
  subnet_id      = aws_subnet.pub_b.id
  route_table_id = aws_route_table.rt_public.id
}

resource "aws_route_table_association" "rt_priv_a" {
  subnet_id      = aws_subnet.priv_a.id
  route_table_id = aws_route_table.rt_private.id
}

resource "aws_route_table_association" "rt_priv_b" {
  subnet_id      = aws_subnet.priv_b.id
  route_table_id = aws_route_table.rt_private.id
}

resource "aws_security_group" "sg_global" {
  name        = "global-security-group"
  description = "global security group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_global"
  }
}
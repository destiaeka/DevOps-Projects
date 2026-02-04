# ==================== VPC======================
resource "aws_vpc" "bastion" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "bastion"
  }
}

resource "aws_vpc" "app" {
  cidr_block       = "172.32.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "app"
  }
}


# ======================= SUBNET =============================
resource "aws_subnet" "bastion-pub-a" {
  vpc_id     = aws_vpc.bastion.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "bastion-pub-a"
  }
}

resource "aws_subnet" "app-pub-a" {
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.32.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "app-pub-a"
  }
}

resource "aws_subnet" "app-priv-a" {
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.32.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "app-priv-a"
  }
}

resource "aws_subnet" "app-priv-b" {
  vpc_id     = aws_vpc.app.id
  cidr_block = "172.32.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "app-priv-b"
  }
}

# ================ IGW ====================
resource "aws_internet_gateway" "igw-bastion" {
  vpc_id = aws_vpc.bastion.id

  tags = {
    Name = "igw-bastion"
  }
}

resource "aws_internet_gateway" "igw-app" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "igw-app"
  }
}
resource "aws_eip" "eip-app" {
  domain   = "vpc"
}

# ============== NGW ======================
resource "aws_nat_gateway" "ngw-app" {
  allocation_id = aws_eip.eip-app.id
  subnet_id     = aws_subnet.app-pub-a.id

  tags = {
    Name = "ngw-app"
  }
}

# ==================== Transit Gateway =====================
resource "aws_ec2_transit_gateway" "tg-bastion-app" {
  description = "trasit gateway for bastion and app"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tg-bastion" {
  subnet_ids         = [aws_subnet.bastion-pub-a.id]
  transit_gateway_id = aws_ec2_transit_gateway.tg-bastion-app.id
  vpc_id             = aws_vpc.bastion.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tg-app" {
  subnet_ids         = [aws_subnet.app-pub-a.id]
  transit_gateway_id = aws_ec2_transit_gateway.tg-bastion-app.id
  vpc_id             = aws_vpc.app.id
}

# ===================== RT Bastion ============================
resource "aws_route_table" "rt-bastion-public" {
  vpc_id = aws_vpc.bastion.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-bastion.id
  }

  route {
    cidr_block = "172.32.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tg-bastion-app.id
  }

  tags = {
    Name = "rt-bastion-public"
  }
}

resource "aws_route_table_association" "bastion-public" {
  subnet_id      = aws_subnet.bastion-pub-a.id
  route_table_id = aws_route_table.rt-bastion-public.id
}

# ===================== RT App Public ========================
resource "aws_route_table" "rt-app-public" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-app.id
  }

  route {
    cidr_block = "192.168.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tg-bastion-app.id
  }

  tags = {
    Name = "rt-app-public"
  }
}

resource "aws_route_table_association" "app-public" {
  subnet_id      = aws_subnet.app-pub-a.id
  route_table_id = aws_route_table.rt-app-public.id
}

# ================= RT App Private ===================
resource "aws_route_table" "rt-app-private" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw-app.id
  }

  route {
    cidr_block = "192.168.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tg-bastion-app.id
  }

  tags = {
    Name = "rt-app-private"
  }
}

resource "aws_route_table_association" "app-private-a" {
  subnet_id      = aws_subnet.app-priv-a.id
  route_table_id = aws_route_table.rt-app-private.id
}
resource "aws_route_table_association" "app-private-b" {
  subnet_id      = aws_subnet.app-priv-b.id
  route_table_id = aws_route_table.rt-app-private.id
}

# ================ SG Bastion ==================
resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "Allow 22"
  vpc_id      = aws_vpc.bastion.id

  ingress {
    from_port = 22
    to_port = 22
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
    Name = "bastion"
  }
}

# ================ SG App ==================
resource "aws_security_group" "app" {
  name        = "app"
  description = "Allow 22, 80"
  vpc_id      = aws_vpc.app.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [aws_vpc.bastion.cidr_block]
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
    Name = "app"
  }
}

# ================ SG NLB ==================
resource "aws_security_group" "nlb" {
  name        = "nlb"
  description = "Allow 80"
  vpc_id      = aws_vpc.app.id

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
    Name = "nlb"
  }
}
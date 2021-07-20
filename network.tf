# -----------------------------------------
# VPC
# -----------------------------------------
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "${var.project-name}"
  tags = {
    Name = "${var.project-name}-vpc"
  }
}
# -----------------------------------------
# Public Network
# -----------------------------------------
# Subnet
resource "aws_subnet" "public_a" {
  availability_zone       = "us-east-2a"
  cidr_block              = "10.0.10.0/24"
  vpc_id                  = aws_vpc.example.id
  map_public_ip_on_launch = true
  tags = {
    Name = "sn-pub-a"
  }
}
resource "aws_subnet" "public_c" {
  availability_zone       = "us-east-2c"
  cidr_block              = "10.0.11.0/24"
  vpc_id                  = aws_vpc.example.id
  map_public_ip_on_launch = true
  tags = {
    Name = "sn-pub-c"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "${var.project-name}-igw"
  }
}
# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "${var.project-name}-rt-pub"
  }
}
# Route
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}
# Route Table Association
resource "aws_route_table_association" "public_a" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_a.id
}
resource "aws_route_table_association" "public_c" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_c.id
}
# -----------------------------------------
# Private Network
# -----------------------------------------
# Subnet
resource "aws_subnet" "private_a" {
  availability_zone       = "us-east-2a"
  cidr_block              = "10.0.20.0/24"
  vpc_id                  = aws_vpc.example.id
  map_public_ip_on_launch = false
  tags = {
    Name = "eks-sn-pri-a"
  }
}
resource "aws_subnet" "private_c" {
  availability_zone       = "us-east-2c"
  cidr_block              = "10.0.21.0/24"
  vpc_id                  = aws_vpc.example.id
  map_public_ip_on_launch = false
  tags = {
    Name = "eks-sn-pri-c"
  }
}
# Route Table
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "${var.project-name}-rt-pri-a"
  }
}
resource "aws_route_table" "private_c" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "${var.project-name}-rt-pri-c"
  }
}
# Route
resource "aws_route" "private_a" {
  route_table_id         = aws_route_table.private_a.id
  nat_gateway_id         = aws_nat_gateway.nat_a.id
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route" "private_c" {
  route_table_id         = aws_route_table.private_c.id
  nat_gateway_id         = aws_nat_gateway.nat_c.id
  destination_cidr_block = "0.0.0.0/0"
}
# Route Table Association
resource "aws_route_table_association" "private_a" {
  route_table_id = aws_route_table.private_a.id
  subnet_id      = aws_subnet.private_a.id
}
resource "aws_route_table_association" "private_c" {
  route_table_id = aws_route_table.private_c.id
  subnet_id      = aws_subnet.private_c.id
}
# Elastic IP Address
resource "aws_eip" "nat_a" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "${var.project-name}-eip-a"
  }
}
resource "aws_eip" "nat_c" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "${var.project-name}-eip-c"
  }
}
# Nat Gateway
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "${var.project-name}-nat-gw-a"
  }
}
resource "aws_nat_gateway" "nat_c" {
  allocation_id = aws_eip.nat_c.id
  subnet_id     = aws_subnet.public_c.id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "${var.project-name}-nat-gw-c"
  }
}
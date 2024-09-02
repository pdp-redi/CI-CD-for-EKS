# create a vpc
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.env}-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# create a internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.env}-igw"
  }
}

# public subnets 
resource "aws_subnet" "public_subnet" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.env}-public-subnet-${each.key}"
  }
}

# public route table 
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env}-public-rt"
  }
}

# # Associate Public Subnets with Public Route Tables
# resource "aws_route_table_association" "public_rt_association" {
#   for_each = { for subnet in aws_subnet.public_subnet : subnet.id => subnet if subnet.map_public_ip_on_launch }

#   subnet_id      = each.value.id
#   route_table_id = aws_route_table.public_rt.id
# }


# Create the Elastic IP for Nat gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.env}-elastic-ip"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet["subnet1"].id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.env}-ngw"
  }
}

# Create Private Subnets
resource "aws_subnet" "private_subnet" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.env}-private-subnet-${each.key}"
  }
}

# Create Private Route Tables
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.env}-private-rt"
  }
}

# # Associate Private Subnets with Private Route Tables
# resource "aws_route_table_association" "private_rt_association" {
#   for_each = { for subnet in aws_subnet.private_subnet : subnet.id => subnet if subnet.map_public_ip_on_launch }

#   subnet_id      = each.value.id
#   route_table_id = aws_route_table.private_rt.id
# }

resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = var.env
  }
}

resource "aws_subnet" "public_subnet" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "eks-public-subnet-${each.key}"
  }
}

resource "aws_subnet" "private_subnet" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "eks-private-subnet-${each.key}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "eks-vpc-igw"
  }
}

resource "aws_route_table" "puble_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "eks-vpc-public-rt"
  }
}

# Create the NAT Gateway for private subnets
resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet["subnet1"].id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "eks-ngw"
  }
}

# Create Route Tables
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Associate Subnets with Route Tables
resource "aws_route_table_association" "public_association" {
  for_each = {
    for key, value in var.public_subnets : key => value if value.map_public_ip_on_launch
  }

  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_route_table_association" "private_association" {
  for_each = {
    for key, value in var.private_subnets : key => value if !value.map_public_ip_on_launch
  }

  subnet_id      = aws_subnet.private_subnet[each.key].id
  route_table_id = aws_route_table.private_rt.id
}
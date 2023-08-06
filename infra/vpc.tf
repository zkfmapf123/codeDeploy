resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true # Enable DNS resolution for the VPC
  enable_dns_hostnames = true # Enable DNS hostnames for the VPC
  tags = {
    Name = "vpc-poc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "igw-poc"
  }
}

resource "aws_subnet" "publics" {
  for_each = {
    "ap-northeast-2a" : "10.0.1.0/24",
    "ap-northeast-2b" : "10.0.2.0/24"
  }

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "${each.key}-public-poc"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rt_mapping" {
  for_each = aws_subnet.publics

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rt.id

}
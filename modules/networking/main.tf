resource "aws_vpc" "ecs_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ecs-vpc"
  }
}

resource "aws_subnet" "public_ecs_subnet" {
  count             = 3
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = count.index == 0 ? var.first_public_subnet_cidr : count.index == 1 ? var.second_public_subnet_cidr : var.third_public_subnet_cidr
  availability_zone = count.index == 0 ? var.first_availability_zone : count.index == 1 ? var.second_availability_zone : var.third_availability_zone
}


resource "aws_subnet" "private_ecs_subnet" {
  count             = 4
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = count.index == 0 ? var.first_private_subnet_cidr : count.index == 1 ? var.second_private_subnet_cidr : count.index == 2 ? var.third_private_subnet_cidr : var.fourth_private_subnet_cidr
  availability_zone = count.index == 0 ? var.first_availability_zone : count.index == 1 ? var.second_availability_zone : count.index == 2 ? var.third_availability_zone : var.first_availability_zone
}


resource "aws_eip" "nat" {
  count = 3
}

resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id
}

resource "aws_nat_gateway" "nat" {
  count         = 3
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public_ecs_subnet[count.index].id
  depends_on    = [aws_internet_gateway.ecs_igw]
}

resource "aws_route_table" "public" {
  count  = 3
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_igw.id
  }
}

resource "aws_route_table" "private" {
  count  = 3
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat.*.id, count.index)
  }
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = element(aws_subnet.public_ecs_subnet.*.id, count.index)
  route_table_id = aws_route_table.public[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = element(aws_subnet.private_ecs_subnet.*.id, count.index)
  route_table_id = aws_route_table.private[count.index].id
}

locals {
  azs = data.aws_availability_zones.available.names
}


data "aws_availability_zones" "available" {
}


resource "random_id" "random" {
  byte_length = 2
}


resource "aws_vpc" "mtc_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  # every time a new vpc is created the new random is generated
  tags = {
    Name = "mtc_vpc-${random_id.random.dec}"
  }

  # Because of IGW we need to create a new VPC attach it to IGW before destroy the old one
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_internet_gateway" "mtc_igw" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "mtc_igw"
  }
}

resource "aws_route_table" "mtc_public_rt" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "mtc_public"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.mtc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mtc_igw.id
}

resource "aws_default_route_table" "mtc_private_rt" {
  default_route_table_id = aws_vpc.mtc_vpc.default_route_table_id

  tags = {
    Name = "mtc_private"
  }
}

resource "aws_subnet" "mtc_public_subnet" {
  #count = length(var.public_cidrs)
  count  = length(local.azs)
  vpc_id = aws_vpc.mtc_vpc.id
  #cidr_block = var.public_cidrs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "mtc_public-${count.index + 1}"
  }
}

resource "aws_subnet" "mtc_private_subnet" {
  #count = length(var.private_cidrs)
  count  = length(local.azs)
  vpc_id = aws_vpc.mtc_vpc.id
  #cidr_block = var.private_cidrs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, length(local.azs) + count.index)
  map_public_ip_on_launch = false
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "mtc_private-${count.index + 1}"
  }
}

# because private subnet is associeted to default route table wich is private
resource "aws_route_table_association" "mtc_public_assoc" {
  count = length(local.azs)
  #subnet_id      = aws_subnet.mtc_public_subnet.*.id[count.index]
  subnet_id      = aws_subnet.mtc_public_subnet[count.index].id
  route_table_id = aws_route_table.mtc_public_rt.id
}

# Always use ressource is prefer than inline declaration
resource "aws_security_group" "mtc_sg" {
  name        = "public_sg"
  description = "Security group for public instances"
  vpc_id      = aws_vpc.mtc_vpc.id
}

resource "aws_security_group_rule" "ingress_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = [var.access_ip, var.jenkins_ip]
  security_group_id = aws_security_group.mtc_sg.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mtc_sg.id
}
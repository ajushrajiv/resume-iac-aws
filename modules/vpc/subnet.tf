locals {
  azs                  = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  public_subnets       = ["10.0.1.0/24", "10.0.3.0/24", "10.0.5.0/24"]
  private_subnets      = ["10.0.2.0/24", "10.0.4.0/24", "10.0.6.0/24"]
  public_subnet_names  = ["public-subnet-1a", "public-subnet-1b", "public-subnet-1c"]
  private_subnet_names = ["private-subnet-1a", "private-subnet-1b", "private-subnet-1c"]
}

resource "aws_subnet" "public" {
  count = length(local.azs)

  vpc_id                  = aws_vpc.resume_main_vpc.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = local.public_subnet_names[count.index]
  }
}

resource "aws_subnet" "private" {
  count = length(local.azs)

  vpc_id            = aws_vpc.resume_main_vpc.id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = local.azs[count.index]
  tags = {
    Name = local.private_subnet_names[count.index]
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.resume_main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.resume_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_rta" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.resume_main_vpc.id
  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_rta" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_nat_gateway" "resume_nat_gw" {
  allocation_id = aws_eip.resume_nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "resume-nat-gateway"
  }
}

resource "aws_eip" "resume_nat_eip" {
  domain = "vpc"
  tags = {
    Name = "resume-nat-eip"
  }
}

resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.resume_nat_gw.id
}



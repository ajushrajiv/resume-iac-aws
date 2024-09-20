resource "aws_vpc" "resume_main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "resume-main-vpc"
  }
}

resource "aws_internet_gateway" "resume_igw" {
  vpc_id = aws_vpc.resume_main_vpc.id
  tags = {
    Name = "resume-main-igw"
  }
}
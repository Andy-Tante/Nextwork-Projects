resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = "Nextwork VPC"
  }
}
resource "aws_subnet" "publicsubnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.publicsubnet
  map_public_ip_on_launch = "true"
  availability_zone       = var.availability_zone
  tags = {
    Name = "Public 1"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Nextwork IG"
  }
}
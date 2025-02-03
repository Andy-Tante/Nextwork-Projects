#DAY1 (BUILD A VIRTUAL PRIVATE CLOUD)
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
#DAY 2 (VPC TRAFFIC FLOW AND SECURITY)
resource "aws_instance" "name" {
  ami                         = "ami-02ccbe126fe6afe82"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.publicsubnet.id
  vpc_security_group_ids      = [aws_security_group.name.id]
  associate_public_ip_address = true
  tags = {
    Name = "Nextwork Instance"
  }
}
#Creating route table
resource "aws_route_table" "routnextwork" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Nextwork route table"
  }
}
#Creating route table association
resource "aws_route_table_association" "routeassociation" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.routnextwork.id
}
#Creating security group
resource "aws_security_group" "name" {
  description = "A security group for Nextwork"
  vpc_id      = aws_vpc.vpc.id
  #Allows INCOMING traffic from HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allows INCOMING traffic from HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allows INCOMING traffic from SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #replace with EC2 IP address
  }
  #Allows OUTGOING traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Nextwork Security Group"
  }
}
#Network Access Control List
resource "aws_network_acl" "name" {
  vpc_id = aws_vpc.vpc.id
  #Allow ssh 
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }
  #Allow HTTP
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  #Allow HTTPS
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  #Allow all outbound rules
  egress {
    rule_no    = 200
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }
  tags = {
    Name = "Nextwork Network ACL"
  }
}

#DAY1 (BUILD A VIRTUAL PRIVATE CLOUD)
#creating a VPC (vpc 1 is requester)
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = "Nextwork 1"
  }
}
#Creating a public subnet
resource "aws_subnet" "publicsubnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.publicsubnet
  map_public_ip_on_launch = "true"
  availability_zone       = var.availability_zone
  tags = {
    Name = "Public 1"
  }
}
#Creating an Igw
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Nextwork IG"
  }
}

#DAY 2 (VPC TRAFFIC FLOW AND SECURITY)
#Creating an instance
resource "aws_instance" "name" {
  ami                         = "ami-02ccbe126fe6afe82" #replace with your own ami-id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.publicsubnet.id
  vpc_security_group_ids      = [aws_security_group.name.id]
  associate_public_ip_address = true
  key_name                    = "terraform-key-pair"
  tags = {
    Name = "Nextwork Public Server"
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
    Name = "Nextwork public route table"
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
  #Allows ICMP traffic (Can be Considered as DAY 5)
  #Ignore this ICMP for now and come back to it on Day 5
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
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
    cidr_blocks = ["0.0.0.0/0"] #Normally in production you don't use this CIDR range as anyone could have access to it, it's best to have a CIDR range your instances fall under and can connect to it securely
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
#Creating Network Access Control List
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

#Day 3 (Creating a Private Subnet)
resource "aws_subnet" "privatesubnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.privatesubnet
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = "false"
  tags = {
    Name = "Private 1"
  }
}
#Route table
resource "aws_route_table" "name" {
  vpc_id = aws_vpc.vpc.id
  route {
    gateway_id = "local"
    cidr_block = "10.1.0.0/16" #VPC internal traffic
  }
  tags = {
    Name = "Nextwork Private Route Table"
  }
}
#Route table association
resource "aws_route_table_association" "name" {
  subnet_id      = aws_subnet.privatesubnet.id
  route_table_id = aws_route_table.name.id
}
#NACL
resource "aws_network_acl" "privatenacl" {
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    action     = "deny"
    rule_no    = 100
    cidr_block = "0.0.0.0/0"
  }
  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    action     = "deny"
    rule_no    = 200
    cidr_block = "0.0.0.0/0"
  }
  tags = {
    Name = "Nextwork Private NACL"
  }
}
#DAY 4 Launch private subnet in an instance
resource "aws_instance" "privateinstance" {
  ami                         = "ami-02ccbe126fe6afe82"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.privatesubnet.id
  vpc_security_group_ids      = [aws_security_group.name.id]
  associate_public_ip_address = false
  key_name                    = "terraform-key-pair"
  tags = {
    Name = "Nextwork Private Server"
  }
}
#DAY 6 VPC PEERING (VPC2 is accepter)
resource "aws_vpc" "vpcpeer" {
  cidr_block = var.vpc2
  tags = {
    Name = "NextWork 2"
  }
}
resource "aws_subnet" "peersubnet" {
  vpc_id                  = aws_vpc.vpcpeer.id
  map_public_ip_on_launch = "true"
  cidr_block              = var.peersubnet
  availability_zone       = var.peerAZ
  tags = {
    Name = "Public 2"
  }
}
resource "aws_security_group" "peersg" {
  vpc_id      = aws_vpc.vpcpeer.id
  description = "Accepter security group"
  ingress {
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  ingress {
    from_port   = "-1"
    to_port     = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "icmp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
  }
  tags = {
    Name = "Security group PEER"
  }
}
resource "aws_instance" "name1" {
  ami                         = "ami-02ccbe126fe6afe82"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.peersg.id]
  subnet_id                   = aws_subnet.peersubnet.id
  associate_public_ip_address = true
  tags = {
    Name = "na"
  }
}
resource "aws_internet_gateway" "peerigw" {
  vpc_id = aws_vpc.vpcpeer.id
}
resource "aws_route_table" "peerroute" {
  vpc_id = aws_vpc.vpcpeer.id
  route {
    gateway_id = aws_internet_gateway.peerigw.id
    cidr_block = "0.0.0.0/0"
  }
}
resource "aws_route_table_association" "name1" {
  subnet_id      = aws_subnet.peersubnet.id
  route_table_id = aws_route_table.peerroute.id
}
resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = aws_vpc.vpc.id #Requester VPC
  peer_vpc_id = aws_vpc.vpcpeer.id #Accepter VPC
  auto_accept = true #Automatically accepts peering request
  tags = {
    Name = "Nextwork VPC Peering"
  }
}
#Route for VPC1 to reach VPC2 through peering
resource "aws_route" "name" {
  route_table_id            = aws_route_table.name.id
  destination_cidr_block    = var.vpc2
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
#Route for VPC2 to reach VPC1 through peering
resource "aws_route" "name1" {
  route_table_id            = aws_route_table.peerroute.id
  destination_cidr_block    = var.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
#Day 7 (VPC Monitoring with flowlogs)
# Create an IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_logs_role" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
# Attach IAM Policy to Allow Logging to CloudWatch
resource "aws_iam_policy_attachment" "flow_logs_policy" {
  name       = "vpc-flow-logs-attachment"
  roles      = [aws_iam_role.flow_logs_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
# Create a CloudWatch Log Group for Storing Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs_group" {
  name              = "/aws/vpc-flow-logs"
  retention_in_days = 30
}
# Enable VPC Flow Logs and Send Logs to CloudWatch
resource "aws_flow_log" "vpc_flow_logs" {
  log_destination      = aws_cloudwatch_log_group.flow_logs_group.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.vpc.id
  iam_role_arn         = aws_iam_role.flow_logs_role.arn
}

#DAY 8 and 9 (Access S3 from vpc and VPC Endpoints)
resource "aws_s3_bucket" "name" {
  bucket = "dobretechbucket"
}
resource "aws_s3_object" "name" {
  for_each = fileset("images/", "*")
  bucket   = aws_s3_bucket.name.id
  key      = each.value
  source   = "images/${each.value}"
  etag     = filemd5("images/${each.value}")
}
#vpc endpoints
resource "aws_vpc_endpoint" "name" {
  vpc_id = aws_vpc.vpc.id
  service_name = "com.amazonaws.eu-central-1.s3"
}

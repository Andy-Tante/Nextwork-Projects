# Welcome to Nextwork's Unofficial Repository!
This is an independent project where I attempt to rebuild some of Nextwork's projects using Terraform as Infrastructure as Code (IaC). This is a learning journey for me, and I hope it proves useful to others as well.

# **Day 1: Building a Virtual Private Cloud (VPC)**
![image](diagrams/1.png)
**Creating the VPC**

We start by provisioning a Virtual Private Cloud (VPC), which serves as the foundational networking layer for our AWS infrastructure. The VPC has a defined CIDR block that determines its IP range.

```
#creating a VPC (vpc 1 is requester)
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = "Nextwork 1"
  }
}
```

**Creating a Public Subnet**

A public subnet is provisioned within the VPC, enabling resources to have direct internet access. This subnet is configured to assign public IPs automatically.

```
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
```

**Attaching an Internet Gateway (IGW)**

An Internet Gateway (IGW) is attached to the VPC to allow communication between the VPC and the internet. This is essential for public-facing resources such as web servers.

```
#Creating an Igw
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Nextwork IG"
  }
}
```

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
**Day 2: VPC Traffic Flow and Security**

**Overview**

This project focuses on setting up a secure and scalable AWS Virtual Private Cloud (VPC) environment using Terraform. The implementation includes:

- Deploying an EC2 instance in a public subnet

- Configuring a route table for internet access

- Creating a security group to control inbound and outbound traffic

- Implementing a Network ACL for additional security at the subnet level

**Infrastructure Components & Explanation**

**1. EC2 Instance Deployment**

We provision an EC2 instance in a public subnet with an assigned public IP, allowing direct internet access. The key properties include:

- AMI: ami-02ccbe126fe6afe82 (Amazon Linux 2)

- Instance Type: t2.micro (suitable for free-tier and lightweight workloads)

- Security Group: Restricts access to only necessary ports (22, 80, 443)

- Associate Public IP Address: true ensures accessibility from the internet

- Key Name (Key Pair): To SSH into our instance

```
#Creating an instance
resource "aws_instance" "name" {
  ami                         = "ami-02ccbe126fe6afe82"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.publicsubnet.id
  vpc_security_group_ids      = [aws_security_group.name.id]
  associate_public_ip_address = true
  key_name                    = "terraform-key-pair"
  tags = {
    Name = "Nextwork Public Server"
  }
}
```

**2.  Route Table for Internet Access**

A route table is created and associated with the public subnet to allow outbound traffic to the internet through an Internet Gateway (IGW).

```
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
```

**Route Table Association**

This ensures that traffic from our public subnet follows the defined routing rules

```
#Creating route table association
resource "aws_route_table_association" "routeassociation" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.routnextwork.id
}
```

**3.  Security Group for EC2 Instance**

A security group acts as a virtual firewall to control inbound and outbound traffic at the instance level. Here’s what it allows:

**Inbound:**

- Port 80 (HTTP): Open to all for web traffic

- Port 443 (HTTPS): Open to all for secure web traffic

- Port 22 (SSH): Open (ideally should be restricted to specific IPs)

```
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
    cidr_blocks = ["0.0.0.0/0"] #replace with EC2 IP address
  }
```

**Outbound:**

Allows all traffic

```
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
```

**4.  Network ACL (NACL) for Additional Security**

Network ACLs provide an extra layer of security by controlling traffic at the subnet level.

**Inbound Rules:**

Allow SSH (22), HTTP (80), HTTPS (443) from all sources

```
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
```

**Outbound Rules:**

The "-1" indicates it allows traffic from all protocols.

```
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
```

**Key Learnings**

- Route Tables are essential for directing network traffic in AWS.

- Security Groups control traffic at the instance level and should be restrictive.

- Network ACLs provide subnet-level security but require careful ordering of rules.

- Public IP assignment allows external access but should be used cautiously.

---------------------------------------------------------------------------------------------------------------------------------
**Day 3: Creating a Private Subnet**

**Overview**

In a VPC (Virtual Private Cloud), we often separate resources into public and private subnets. A private subnet is used for instances that should not be directly accessible from the internet, such as databases or backend servers.

**Key Features of a Private Subnet:**

✅ No public IP assigned to instances.

✅ Cannot directly access or be accessed from the internet.

✅ Communicates only within the VPC or through a NAT Gateway (if needed).

**In this setup, we’ll:**

Create a private subnet.

Attach a route table that only allows internal VPC communication.

Configure a Network ACL (NACL) to block all traffic for security.

**1. Setting Up a Private Subnet**

A private subnet is created within the VPC. Unlike public subnets, instances in this subnet do not get a public IP and cannot directly access the internet.

```
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
```

**2. Private Route Table**

Since this subnet is private, its route table does not allow traffic to the internet. It only allows internal communication within the VPC.

```
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
```

```
#Route table association
resource "aws_route_table_association" "name" {
  subnet_id      = aws_subnet.privatesubnet.id
  route_table_id = aws_route_table.name.id
}
```

**3. Network ACL (NACL) – Denying All Traffic**

NACLs provide an extra security layer by controlling traffic at the subnet level. Here, we deny all inbound and outbound traffic to make the subnet fully isolated.

```
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
```

**Summary**

✅ Created a private subnet with no public IPs.

✅ Configured a private route table to allow only internal VPC traffic.

✅ Applied a strict NACL that blocks all traffic, ensuring complete isolation.

This setup is fully secure and can be used for databases, backend applications, or any resource that should not be exposed to the internet.

----------------------------------------------------------------------------
**# Day 4: Launching a Private Instance**

On Day 4, we focused on deploying an EC2 instance in the private subnet while troubleshooting SSH access issues due to security configurations.

**Key Actions Taken:**

**Created a Private Instance:**

- Launched an EC2 instance inside the private subnet.

- Attached a security group with SSH, HTTP, and HTTPS rules.

- Assigned a key pair for SSH authentication.

- Ensured no public IP was assigned, keeping the instance private.

```
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
```

**Encountered SSH Access Issues:**

- While trying to SSH into the private instance, authentication failed.

- The issue was traced back to NACL rules that were blocking all inbound and outbound traffic.

**Public Instance Verification:**

- Confirmed that the public instance (configured on Day 2) had working SSH access.

- The key pair used in the public subnet allowed successful authentication.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Day 5: Testing VPC Connectivity 🚀**

Today, I tested connectivity between my public and private instances by pinging the private instance from the public one. As expected—it didn't work. But why? 🤔

Could it be due to the NACL rules, which were set to deny all inbound and outbound traffic by default? To test this, I modified the NACL rules to allow all traffic. Did it work? No.

So, what was the problem? After troubleshooting, I realized that ICMP traffic (used for ping) was not allowed in the Security Group. To fix this, I had to add an ingress rule allowing ICMP traffic in the Security Group.

**What is ICMP?**

ICMP (Internet Control Message Protocol) is a network protocol used for diagnostics and error reporting, commonly used in ping and traceroute commands.

```
ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
```

Since Security Groups manage instance-level traffic, I added the rule under #Day2 - Allows ICMP traffic (Considered as Day 5) in my Terraform configuration. Finally, as shown below, pinging the private instance was successful! ✅

Next, I tested internet connectivity from the public subnet by running:

curl https://learn.nextwork.org/projects/aws-host-a-website-on-s3

And it worked perfectly! 🎉

This experience reinforced the importance of understanding how Security Groups and NACLs work together in AWS networking.

------------------------------------------------------------------------------------
**DAY 6: VPC PEERING**

This Terraform configuration sets up a VPC peering connection where VPC2 (Accepter) is peered with another VPC (VPC1, REQUESTER). It provisions a subnet, an EC2 instance, a security group, an internet gateway, and necessary route tables for routing traffic between the peered VPCs.

The terraform configuration below is for setting up a second VPC, remember we have a VPC we had created before and that will be our VPC 1.

```
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
```
--------------------------------------------------------------------------------
**DAY 7: VPC Monitoring with Flow Logs**

This section configures VPC Flow Logs to monitor traffic within the VPC. Flow Logs capture information about the IP traffic going to and from network interfaces in your VPC.

**Key Components**

- **IAM Role for VPC Flow Logs:** 
Grants permissions to publish logs to CloudWatch.

- **IAM Policy Attachment:** 
Grants full access to CloudWatch Logs.

- **CloudWatch Log Group:** 
Stores the VPC Flow Logs.

- **VPC Flow Logs Configuration:** 
Enables monitoring for all traffic types.

```
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
```
**Generating and Viewing VPC Flow Logs**

**Generating Logs by Pinging an Instance**

- **Launch an EC2 Instance:** 
Ensure an instance is running inside the monitored VPC. (we have instnaces form the previous porjects you can use)

- **Allow ICMP Traffic:** 
The security group attached to the instance must allow inbound ICMP traffic (ping requests).

- **Ping the Instance:** 
From another instance or your local machine, run:

ping <EC2_PUBLIC_IP>

This generates network traffic that will be logged in VPC Flow Logs.

**Viewing Logs in CloudWatch**

- Open AWS Console and navigate to CloudWatch.

- Click on Log Groups in the left menu.

- Find and select /aws/vpc-flow-logs.

- Click on the latest log stream to view traffic data.

- Logs will display information like source IP, destination IP, port, protocol, and whether the traffic was allowed or denied.

----------------------------------------------------------------------------
**DAY 8 and 9: Access S3 from VPC and VPC Endpoints**

We will create an S3 bucket, upload images from a specified directory to the bucket, and set up a VPC endpoint to enable secure access to the S3 bucket from within our Virtual Private Cloud (VPC).

```
resource "aws_s3_bucket" "name" {
  bucket = "dobretechbucket"
}
```

- **resource "aws_s3_bucket" "name":** 
This block defines an S3 bucket resource.

- **bucket:** 
The name of the S3 bucket to be created. In this case, it’s named dobretechbucket. Ensure this name is unique across all S3 buckets in AWS.
```
resource "aws_s3_object" "name" {
  for_each = fileset("images/", "*")
  bucket   = aws_s3_bucket.name.id
  key      = each.value
  source   = "images/${each.value}"
  etag     = filemd5("images/${each.value}")
}
```
- **resource "aws_s3_object" "name":** 
This block defines an S3 object resource.

- **for_each = fileset("images/", "*"):** 
This iterates over each file in the images/ directory, allowing you to upload multiple images at once.

- **bucket:** Specifies the S3 bucket where the objects will be uploaded.

- **key:** The name of the object in the bucket, which corresponds to the filename.

- **source:** The path to the local file that will be uploaded to the S3 bucket.

- **etag:** 
A unique identifier for the object, generated from the file's MD5 hash. This ensures that the object will be re-uploaded only if it has changed.

**VPC ENDPOINT**

VPC endpoints gives your VPC private, direct access to other AWS services like S3, so traffic doesn't need to go through the internet.

Just like how internet gateways are like your VPC's door to the internet, you can think of VPC endpoints as private doors to specific AWS services.
In this case we want to access our S3 bucket

```
resource "aws_vpc_endpoint" "name" {
  vpc_id = aws_vpc.vpc.id
  service_name = "com.amazonaws.eu-central-1.s3"
}
```
![images](images/images.jpeg)
- SSH into your instance and run: aws s3 ls s3://<bucketname> to see the files inside. For first timers, you'll be prompted to run aws configure to pass in your Access and secret keys before you see your s3 bucket.
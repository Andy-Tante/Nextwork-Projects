# Welcome to Nextwork's Unofficial Repository!
This is an independent project where I attempt to rebuild some of Nextwork's projects using Terraform as Infrastructure as Code (IaC). This is a learning journey for me, and I hope it proves useful to others as well.

**Day 1:  Building a Virtual Private Cloud (VPC)**

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

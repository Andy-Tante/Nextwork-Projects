# Welcome to Nextwork's Unofficial Repository!
This is an independent project where I attempt to rebuild some of Nextwork's projects using Terraform as Infrastructure as Code (IaC). This is a learning journey for me, and I hope it proves useful to others as well.

**Day 1:  Building a Virtual Private Cloud (VPC)**

**Creating the VPC**

We start by provisioning a Virtual Private Cloud (VPC), which serves as the foundational networking layer for our AWS infrastructure. The VPC has a defined CIDR block that determines its IP range.

**Creating a Public Subnet**

A public subnet is provisioned within the VPC, enabling resources to have direct internet access. This subnet is configured to assign public IPs automatically.

**Attaching an Internet Gateway (IGW)**

An Internet Gateway (IGW) is attached to the VPC to allow communication between the VPC and the internet. This is essential for public-facing resources such as web servers.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
**Day 2: VPC Traffic Flow and Security - Terraform Implementation**

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

**2.  Route Table for Internet Access**

A route table is created and associated with the public subnet to allow outbound traffic to the internet through an Internet Gateway (IGW).

**Route Table Association**

This ensures that traffic from our public subnet follows the defined routing rules

**3.  Security Group for EC2 Instance**

A security group acts as a virtual firewall to control inbound and outbound traffic. Here’s what it allows:

**Inbound:**

- Port 80 (HTTP): Open to all for web traffic

- Port 443 (HTTPS): Open to all for secure web traffic

- Port 22 (SSH): Open (ideally should be restricted to specific IPs)

**Outbound:**

Allows all traffic

**4.  Network ACL (NACL) for Additional Security**

Network ACLs provide an extra layer of security by controlling traffic at the subnet level.

**Inbound Rules:**

Allow SSH (22), HTTP (80), HTTPS (443) from all sources

**Outbound Rules:**

Allow all traffic

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

**2. Private Route Table**

Since this subnet is private, its route table does not allow traffic to the internet. It only allows internal communication within the VPC.

**3. Network ACL (NACL) – Denying All Traffic**

NACLs provide an extra security layer by controlling traffic at the subnet level. Here, we deny all inbound and outbound traffic to make the subnet fully isolated.

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

Since Security Groups manage instance-level traffic, I added the rule under #Day2 - Allows ICMP traffic (Considered as Day 5) in my Terraform configuration. Finally, as shown below, pinging the private instance was successful! ✅

Next, I tested internet connectivity from the public subnet by running:

curl https://learn.nextwork.org/projects/aws-host-a-website-on-s3

And it worked perfectly! 🎉

This experience reinforced the importance of understanding how Security Groups and NACLs work together in AWS networking.
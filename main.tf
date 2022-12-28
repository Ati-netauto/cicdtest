
terraform{
    required_providers {
      aws={
           source="hashicorp/aws"
      }
    }
}


provider "aws"{
    profile ="default"
    region = "eu-west-2"
    
}


# 1.Create VPC #

resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support= "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    instance_tenancy = "default"
        tags= {
        Name= "prod.vpc"
    }
    
  }

# 2.Create internet Gateway #

resource "aws_internet_gateway" "prod-igw" {
    vpc_id = aws_vpc.prod-vpc.id
    tags= {
        Name="prod.igw"
    }    
  
}

# 3.Create subnet #

resource "aws_subnet" "prod-pub-subnet" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = "10.0.172.0/24"
    map_public_ip_on_launch = "true"

    tags = {
        Name="prod-pub-subnet"
    }
  
}

# 4.Create a custom route table #

resource "aws_route_table" "prod-pub-crt" {
    vpc_id = aws_vpc.prod-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.prod-igw.id

        
        }
    }


# 5.Associate custom route table with the subnet #

resource "aws_route_table_association" "prod-crt1-public-subnet" {
  subnet_id = aws_subnet.prod-pub-subnet.id
  route_table_id = aws_route_table.prod-pub-crt.id
}


# 6.Create a Security group #

resource "aws_security_group" "prod-sg" {
    name = "prod-sg"
    description = "Allow inbound http traffic"
    vpc_id= aws_vpc.prod-vpc.id

    ingress {
        description = "Allow web port"
        from_port = 8050
        to_port = 8050
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "http access from the internet"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "https access from the internet"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "ssh access from the internet"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "allow ping traffic"
        from_port = 8
        to_port = 0
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      "Name" = "prod-sg"
    }
}

# 7. Create EC2 instance
resource "aws_instance" "jenkins-server" {
    ami="ami-03542b5588cd0e6b3"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.prod-pub-subnet.id
    security_groups = [ aws_security_group.prod-sg.id ]
    # user_data = <<-EOF
    #             #!/bin/bash
    #             sudo apt update
    #             sudo apt install -y nodejs npm
    #             sudo wget https://github.com/Ati-netauto/helloworld/raw/main/helloword2.js
    #             node helloword2.js
    #             EOF
}


## Troubleshooting - if there are any issues please check the logs here /var/log/cloud-init-output.log ####






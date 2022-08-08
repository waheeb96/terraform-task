terraform {
required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
  access_key = "access_key" 
  secret_key = "secret_key"
}

resource "aws_vpc" "vpc" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "eu-central-1b"
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "agw" {
    vpc_id = aws_vpc.vpc.id

    tags = {
      Name = "sj-gw"
    }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route =[ {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.agw.id
    carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      nat_gateway_id             = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
  } 
  ]
  tags = {
    Name = "rt"
  }
}
resource "aws_route_table_association" "rt-association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg-wp" {
name = "WordPress-sg"
description = "Allow SSH and HTTP inbound traffic"
vpc_id=aws_vpc.vpc.id

ingress {
description = "SSH traffic"
from_port= 22
to_port= 22
protocol= "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
description = "HTTP traffic"
from_port = 80
to_port= 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress {
description= "Ping"
from_port = -1
to_port = -1
protocol= "icmp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}

tags =  {
Name="WordPress-sg"
}
}

resource "aws_security_group" "sg-mysql" {
name = "Mysql-sg"
description = "Allow WordPress inbound traffic"
vpc_id = aws_vpc.vpc.id

ingress {
description = "WordPress traffic"
from_port = 3306
to_port = 3306
protocol = "tcp"
security_groups =  [aws_security_group.sg-wp.id]
}
egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks =  ["0.0.0.0/0"]
}
depends_on = [
  aws_security_group.sg-wp,
]
tags = {
    Name="Mysql-sg"
}

}



resource "aws_instance" "mysql" {
ami = "ami-065deacbcaac64cf2"
instance_type = "t2.micro"
key_name = "terraform"
associate_public_ip_address = true
subnet_id =  aws_subnet.private_subnet.id
vpc_security_group_ids = [aws_security_group.sg-mysql.id]
availability_zone = "eu-central-1b"
tags = {
Name = "mysql"
}
}

resource "aws_instance" "wordpress" {
ami = "ami-065deacbcaac64cf2"
instance_type = "t2.micro"
key_name = "terraform"
associate_public_ip_address = true
subnet_id = aws_subnet.public_subnet.id
vpc_security_group_ids = [aws_security_group.sg-wp.id]
availability_zone = "eu-central-1a"

tags = {
Name = "wordpress"
}
}

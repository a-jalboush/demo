provider "aws" {
  region = "us-west-2"
}

# create a VPC

resource "aws_vpc" "first-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "dev"
  }
}

# create internet gateway

resource "aws_internet_gateway" "first-gw" {
  vpc_id = aws_vpc.first-vpc.id

  tags = {
    Name = "dev"
  }
}

# create a custom route table

resource "aws_route_table" "first-rt" {
  vpc_id = aws_vpc.first-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.first-gw.id
  }

  tags = {
    Name = "dev"
  }
}

# create a subnet

resource "aws_subnet" "first-subnet" {
  vpc_id     = aws_vpc.first-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "dev"
  }
}

# Associate a subnet to route table

resource "aws_route_table_association" "first-rta" {
  subnet_id      = aws_subnet.first-subnet.id
  route_table_id = aws_route_table.first-rt.id

}

# create a security group 

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.first-vpc.id

  ingress {
    description = "https from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "aah from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev"
  }
}

# create netwrok interface

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.first-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

tags = {
  Name = "dev"  
 }
}

# Create public IP

resource "aws_eip" "web-server_eip" {
  #domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.first-gw]
}

output "server_public_ip" {
  value = aws_eip.web-server_eip.public_ip
}

# create ubuntu server

resource "aws_instance" "web-server" {
  ami           = "ami-0cf2b4e024cdb6960"
  instance_type = "t2.micro"
  availability_zone = "us-west-2a"
  key_name = "aj-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2
            sudo bash -c 'echo your first web server > /var/www/html/index.html'
            EOF 

 tags = {
    Name = "dev"
  }

}
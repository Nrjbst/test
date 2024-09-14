provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "DipVpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    name = "Nrj-vpc"
  }
}

######### subnet #############
resource "aws_subnet" "mySubnet" {
  vpc_id     = aws_vpc.DipVpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Nrj-subnet"
  }
}

############ Internet Gateway ############

resource "aws_internet_gateway" "myGateway" {
  vpc_id = aws_vpc.DipVpc.id

  tags = {
    Name = "Nrj-InternetGateway"
  }

}

###### route table ##########
resource "aws_route_table" "my_routeTable" {
  vpc_id = aws_vpc.DipVpc.id

  route {
    cidr_block = "10.1.1.0/24"
    gateway_id = aws_internet_gateway.myGateway.id
  }

  tags = {
    Name = "nrj-RouteTable"
  }
}

############ route table association ######
resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.mySubnet.id
  route_table_id = aws_route_table.my_routeTable.id
}

######### route ############
resource "aws_route" "myRoute" {
  route_table_id            = aws_route_table.my_routeTable.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.myGateway.id
  depends_on = [aws_route_table.my_routeTable]

}

########## security group  ############
resource "aws_security_group" "MySg" {
  name = "Allow_inbound_traffic"
  vpc_id = aws_vpc.DipVpc.id
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "nrj-securityGroup"
  }
}
############################## key pair ###################################
resource "aws_key_pair" "instance-key" {
  key_name   = "instance-key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

###### store the private key locally ##########
resource "local_file" "key_tf" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tfKey"
}
########## ec2 ###############

resource "aws_instance" "web" {
  ami           = "ami-09040d770ffe2224f"
  instance_type = "t2.micro"
  key_name = "instance-key"

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello World" > hello.txt
                EOF

  tags = {
    Name = "HelloWorld"
  }
}

output "public_ip_of_instance" {
  value = aws_instance.web.public_ip
}

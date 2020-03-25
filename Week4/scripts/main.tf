provider "aws" {
    profile = "default"
	region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "vpc-week4"
  }
}

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "sn-public-week4"
  }
}

resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "sn-private-week4"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "igw-week4"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags = {
    Name = "rt-public-week4"
  }
}

resource "aws_route_table_association" "rta_public" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "public" {
  name = "public-sg-week4"
  description = "Allow ssh, http access"
  vpc_id = "${aws_vpc.main.id}"
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private" {
  name = "private-sg-week4"
  description = "Allow subnet 10.0.1.0/24 access"
  vpc_id = "${aws_vpc.main.id}"
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "public" {
  ami = "ami-0fc61db8544a617ed"
  instance_type = "t2.micro"
  key_name = "aws-course-key-pair-useast1"
  subnet_id = "${aws_subnet.public.id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.public.id}"]
  user_data = <<-EOF
				#! /bin/bash
				sudo su
				yum update -y
				yum install httpd -y
				service httpd start
				chkconfig httpd on
				cd /var/www/html
				echo "<html><h1>This is Web Server from public subnet<h1><html>" > index.html
				EOF
		
  tags = {
    Name = "ec2-public-week4"
	TargetGroup = "yes"
  }
}

resource "aws_instance" "private" {
  ami = "ami-0fc61db8544a617ed"
  instance_type = "t2.micro"
  key_name = "aws-course-key-pair-useast1"
  subnet_id = "${aws_subnet.private.id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.private.id}"]  
  user_data = <<-EOF
				#! /bin/bash
				sudo su
				yum update -y
				yum install httpd -y
				service httpd start
				chkconfig httpd on
				cd /var/www/html
				echo "<html><h1>This is Web Server from private subnet<h1><html>" > index.html
				EOF
  
  tags = {
    Name = "ec2-private-week4"
	TargetGroup = "yes"
  }
}

data "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"
  filter {
    name   = "association.main"
    values = ["true"]
  }
}


resource "aws_instance" "nat" {
  ami = "ami-00a9d4a05375b2763"
  instance_type = "t2.micro"
  key_name = "aws-course-key-pair-useast1"
  subnet_id = "${aws_subnet.public.id}"
  associate_public_ip_address = "true"
  source_dest_check = "false"
  security_groups = ["${aws_security_group.public.id}"]
  
  tags = {
    Name = "ec2-nat-week4"
  }
}

resource "aws_route" "route" {
  route_table_id            = "${data.aws_route_table.main.id}"
  destination_cidr_block    = "0.0.0.0/0"
  instance_id = "${aws_instance.nat.id}"
}

resource "aws_lb_target_group" "main" {
  name = "tg-week4"
  port = 80
  protocol = "HTTP"
  vpc_id = "${aws_vpc.main.id}"
  health_check {
    protocol = "HTTP"
    path = "/index.html"
  }
  tags = {
    name = "tg-week4"
  } 
}

resource "aws_lb_target_group_attachment" "tg1" {
  target_group_arn = "${aws_lb_target_group.main.arn}"
  target_id = aws_instance.private.id
  port = 80
}

resource "aws_lb_target_group_attachment" "tg2" {
  target_group_arn = "${aws_lb_target_group.main.arn}"
  target_id = aws_instance.public.id
  port = 80
}

resource "aws_lb" "main" {
  name = "lb-week4"
  internal = false
  security_groups = ["${aws_security_group.public.id}"]
  subnets = ["${aws_subnet.public.id}", "${aws_subnet.private.id}"]
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = "${aws_lb.main.arn}"
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.main.arn}"
  }
}


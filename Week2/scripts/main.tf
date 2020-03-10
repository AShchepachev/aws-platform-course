provider "aws" {
  profile    = "default"
  region     = "us-east-1"
}

resource "aws_security_group" "allow_ssh_http" {
  name = "allow_ssh"
  description = "Allow ssh, http access"

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

	egress {
      from_port = 0
      to_port = 64000
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }  
}

resource "aws_iam_instance_profile" "profileS3access" {
    name = "myprofile-profileS3access"
    role = "myRoleS3FullAccessForEC2-Week2"
}

resource "aws_launch_configuration" "lconf" {
	name = "myLC-terraform-week2"
	image_id = "ami-0fc61db8544a617ed"
    instance_type = "t2.micro"
	security_groups = ["${aws_security_group.allow_ssh_http.id}"]
	key_name = "aws-course-key-pair-useast1"
	iam_instance_profile = "${aws_iam_instance_profile.profileS3access.id}"
	user_data = <<-EOF
				#! /bin/bash
				sudo yum -y update
				wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u241-b07/1f5b5a70bf22433b84d0e960903adac8/jdk-8u241-linux-x64.rpm
				sudo rpm -i jdk-8u241-linux-x64.rpm
				mkdir -m 777 /home/ec2-user/files
				aws s3 sync s3://aws-course-art-bucket-101 home/ec2-user/files/
				EOF
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_autoscaling_group" "asg" {
  availability_zones = ["us-east-1c"]
  name = "myASG-terraform-week2"
  max_size = 2
  min_size = 2
  force_delete = true
  launch_configuration = "${aws_launch_configuration.lconf.name}"
}
provider "aws" {
    profile = "default"
	region = "us-east-1"
}

resource "aws_security_group" "allow_ssh_http" {
    name = "mySG-allow_ssh-week3"
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
		to_port = 65535
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_security_group" "allow_rds" {
    name = "mySG-allow_rds-week3"
	description = "Allow RDS access"

    ingress {
        from_port = 5432
		to_port = 5432
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
		to_port = 65535
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_iam_instance_profile" "profileS3access" {
    name = "myprofile-profileS3access"
    role = "myRoleFullAccessForEC2-Week3"
}

resource "aws_instance" "myEC2-week3" {
    ami = "ami-0fc61db8544a617ed"
	instance_type = "t2.micro"
	security_groups = ["${aws_security_group.allow_ssh_http.name}"]
	key_name = "aws-course-key-pair-useast1"
	iam_instance_profile = "${aws_iam_instance_profile.profileS3access.id}"
	user_data = <<-EOF
				#! /bin/bash
				sudo yum -y update
				sudo amazon-linux-extras enable postgresql10
				sudo yum install -y https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/postgresql11-libs-11.7-1PGDG.rhel7.x86_64.rpm
				sudo yum install -y https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/postgresql11-11.7-1PGDG.rhel7.x86_64.rpm
				mkdir -m 777 /home/ec2-user/scripts
				aws s3 cp s3://bucket-week3/rds-script.sql home/ec2-user/scripts/rds-script.sql
				aws s3 cp s3://bucket-week3/dynamodb-script.sh home/ec2-user/scripts/dynamodb-script.sh
				EOF
}

resource "aws_db_instance" "default" {
    allocated_storage = 10
	engine = "postgres"
	instance_class = "db.t2.micro"
	identifier = "dbpostgres-week3"
	port = 5432
	skip_final_snapshot = true
	publicly_accessible = true
	vpc_security_group_ids   = ["${aws_security_group.allow_rds.id}"]
	username = "postgresadmin"
	password = "postgresadmin"
}


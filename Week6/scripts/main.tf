provider "aws" {
  profile = "default"
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-week6"
  }
}

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "sn-public-week6"
  }
}

resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "sn-private-week6"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "igw-week6"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags = {
    Name = "rt-public-week6"
  }
}

resource "aws_route_table_association" "rta_public" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "public" {
  name = "public-sg-week6"
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
  name = "private-sg-week6"
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

resource "aws_security_group" "allow_rds" {
  name = "allow_rds-sg-week6"
  description = "Allow RDS access"
  vpc_id = "${aws_vpc.main.id}"

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


resource "aws_iam_role" "publicEC2" {
  name = "roleForPublicEC2-Week6"
  description = "Allows EC2 instances to access DybamoDB, S3, SNS, SQS"  
  assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [{
		"Action": "sts:AssumeRole",
		"Principal": {
			"Service": "ec2.amazonaws.com"
		},
		"Effect": "Allow",
		"Sid": ""
	}]
}
EOF
}

resource "aws_iam_role" "privateEC2" {
  name = "roleForPrivateEC2-Week6"
  description = "Allows EC2 instances to access RDS, S3, SNS, SQS"
  assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [{
		"Action": "sts:AssumeRole",
		"Principal": {
			"Service": "ec2.amazonaws.com"
		},
		"Effect": "Allow",
		"Sid": ""
	}]
}
EOF
}

resource "aws_iam_role_policy_attachment" "public-DynamoDB" {
  role = "${aws_iam_role.publicEC2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "public-S3" {
  role = "${aws_iam_role.publicEC2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "public-SNS" {
  role = "${aws_iam_role.publicEC2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "public-SQS" {
  role = "${aws_iam_role.publicEC2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}


resource "aws_iam_role_policy_attachment" "private-RDS" {
  role = "${aws_iam_role.privateEC2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_role_policy_attachment" "private-S3" {
  role = "${aws_iam_role.privateEC2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "private-SNS" {
  role = "${aws_iam_role.privateEC2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "private-SQS" {
  role = "${aws_iam_role.privateEC2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}




resource "aws_iam_instance_profile" "profileForPublic" {
  name = "myprofile-profileForPublic"
  role = "${aws_iam_role.publicEC2.name}"
}

resource "aws_iam_instance_profile" "profileForPrivate" {
  name = "myprofile-profileForPrivate"
  role = "${aws_iam_role.privateEC2.name}"
}



resource "aws_db_subnet_group" "main" {
  name = "dbsng-week6"
  subnet_ids = ["${aws_subnet.public.id}", "${aws_subnet.private.id}"]

  tags = {
    Name = "dbsng-week6"
  }
}

resource "aws_db_instance" "main" {
  allocated_storage = 20
  engine = "postgres"
  instance_class = "db.t2.micro"
  identifier = "dbpostgres-week6"
  publicly_accessible = false
  db_subnet_group_name = "${aws_db_subnet_group.main.name}"
  port = 5432
  skip_final_snapshot = true
  name = "EduLohikaTrainingAwsRds"
  username = "rootuser"
  password  = "rootuser"
  vpc_security_group_ids = ["${aws_security_group.allow_rds.id}"]
}

resource "aws_launch_configuration" "main" {
	name = "myLC-terraform-week6"
	image_id = "ami-0fc61db8544a617ed"
    instance_type = "t2.micro"
	security_groups = ["${aws_security_group.public.id}"]
	key_name = "aws-course-key-pair-useast1"
	iam_instance_profile = "${aws_iam_instance_profile.profileForPublic.id}"
	user_data = <<-EOF
				#! /bin/bash
				sudo yum -y update
				mkdir -m 777 /home/ec2-user/files
				aws s3 cp s3://bucket-week6/calc-0.0.1-SNAPSHOT.jar home/ec2-user/files/calc-0.0.1-SNAPSHOT.jar
				aws s3 cp s3://bucket-week6/jdk-8u251-linux-x64.rpm home/ec2-user/files/jdk-8u251-linux-x64.rpm
				sudo rpm -i /home/ec2-user/files/jdk-8u251-linux-x64.rpm
				sudo java -jar /home/ec2-user/files/calc-0.0.1-SNAPSHOT.jar
				EOF
}

resource "aws_autoscaling_group" "main" {
  name = "myASG-terraform-week6"
  vpc_zone_identifier = ["${aws_subnet.public.id}"]
  max_size = 2
  min_size = 2
  force_delete = true
  launch_configuration = "${aws_launch_configuration.main.name}"
}

resource "aws_instance" "private" {
  ami = "ami-0fc61db8544a617ed"
  instance_type = "t2.micro"
  key_name = "aws-course-key-pair-useast1"
  subnet_id = "${aws_subnet.private.id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.private.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.profileForPrivate.id}"
  user_data = <<-EOF
    			#! /bin/bash
    			sudo yum -y update
    			wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u241-b07/1f5b5a70bf22433b84d0e960903adac8/jdk-8u241-linux-x64.rpm
    			sudo rpm -i jdk-8u241-linux-x64.rpm
    			mkdir -m 777 /home/ec2-user/files
    			aws s3 cp s3://bucket-week6/persist3-0.0.1-SNAPSHOT.jar home/ec2-user/files/persist3-0.0.1-SNAPSHOT.jar
				export "RDS_HOST=${aws_db_instance.main.endpoint}"
				sudo java -jar /home/ec2-user/files/persist3-0.0.1-SNAPSHOT.jar
    			EOF

  tags = {
    Name = "ec2-private-week6"
	TargetGroup = "yes"
  }
}

data "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"
  filter {
    name = "association.main"
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
    Name = "ec2-nat-week6"
  }
}

resource "aws_route" "route" {
  route_table_id = "${data.aws_route_table.main.id}"
  destination_cidr_block = "0.0.0.0/0"
  instance_id = "${aws_instance.nat.id}"
}

resource "aws_lb_target_group" "main" {
  name = "tg-week6"
  port = 80
  protocol = "HTTP"
  vpc_id = "${aws_vpc.main.id}"
  health_check {
    protocol = "HTTP"
    path = "/HEALTH"
  }
  tags = {
    name = "tg-week6"
  } 
}

resource "aws_autoscaling_attachment" "main" {
  autoscaling_group_name = "${aws_autoscaling_group.main.id}"
  alb_target_group_arn = "${aws_lb_target_group.main.arn}"
}

resource "aws_lb_target_group_attachment" "tg1" {
  target_group_arn = "${aws_lb_target_group.main.arn}"
  target_id = aws_instance.private.id
  port = 80
}

resource "aws_lb" "main" {
  name = "lb-week6"
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

resource "aws_dynamodb_table" "main" {
  billing_mode = "PROVISIONED"
  read_capacity = 20
  write_capacity = 20
  name = "edu-lohika-training-aws-dynamodb"
  hash_key = "UserName"

  attribute {
    name = "UserName"
    type = "S"
  }
}


resource "aws_sns_topic" "main" {
  name = "edu-lohika-training-aws-sns-topic"

  tags = {
    Name = "sns-topic-week6"
  }
}

resource "aws_sns_topic_subscription" "mymobile" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "SMS"
  endpoint = "+380xxxxxxxxx"
}

resource "aws_sqs_queue" "main" {
  name = "edu-lohika-training-aws-sqs-queue"
  fifo_queue = false
  content_based_deduplication = false
}

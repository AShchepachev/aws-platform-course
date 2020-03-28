provider "aws" {
    profile = "default"
	region = "us-east-1"
}

resource "aws_sqs_queue" "terraform_queue" {
  name = "sqs-week5.fifo"
  fifo_queue = true
  content_based_deduplication = false
}

resource "aws_sns_topic" "main" {
  name = "sns-topic-week5"
}

resource "aws_sns_topic_subscription" "mymobile" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "SMS"
  endpoint = "+380xxxxxxxxx"
}

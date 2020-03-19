#!/bin/bash
bucketName=bucket-week3
aws s3 mb s3://$bucketName
aws s3api put-bucket-versioning --bucket $bucketName --versioning-configuration Status=Enabled
aws s3 cp D:/AWS/Course/rds-script.sql  s3://$bucketName
aws s3 cp D:/AWS/Course/dynamodb-script.sh  s3://$bucketName

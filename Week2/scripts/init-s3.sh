#!/bin/bash
bucketName=aws-course-art-bucket-101
aws s3 mb s3://$bucketName
aws s3api put-bucket-versioning --bucket $bucketName --versioning-configuration Status=Enabled
aws s3 cp D:/AWS/Course/helloAS.txt  s3://$bucketName


myRoleS3FullAccessForEC2-Week2
#!/bin/bash
tableName=Villains
aws dynamodb list-tables
aws dynamodb create-table \
    --table-name $tableName \
    --attribute-definitions AttributeName=Country,AttributeType=S AttributeName=Person,AttributeType=S \
    --key-schema AttributeName=Country,KeyType=HASH AttributeName=Person,KeyType=RANGE \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
aws dynamodb wait table-exists --table-name $tableName
aws dynamodb batch-write-item \
    --request-items file://request-items.json
aws dynamodb query \
    --table-name $tableName \
    --projection-expression "Country, Person" \
	--key-condition-expression "Country = :country" \
    --expression-attribute-values '{
        ":country": { "S": "Russia" }
    }'

#!/bin/bash

#let's create variables AMI ID, SG ID, instances array
START_TIME=$(date +%s)
AMI_ID=ami-09c813fb71547fc4f
INSTANCE_TYPE=t3.micro
SG_ID=sg-03de6c7ee76a1f5a3
INSTANCES=("mongodb" "frontend" "catalogue") #how many instances you need give their names here
ZONE_ID=Z02829133T93YRRJ2VRGM
DOMAIN_NAME=robotshop.site

# now let's write a for loop which creates any no.of instances based on list
# provided in instances array

for instance in $@
do
# search in google for script to create instances in aws cli
#modify the script based on ur needs
#here i dont want key pair, subnet etc so removed those portions and taken which is required for me
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value= $instance}]" --query "Instances[*].InstanceId" --output text)
    if [ $instance == "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
        RECORD_NAME=$DOMAIN_NAME
    else
        IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
        RECORD_NAME=$instance.$DOMAIN_NAME
    fi
    #script to update dns created with ip's of newly created servers
    aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch '{
  "Comment": "Auto update DNS for '"$instance"'",
  "Changes": [
    {
      "Action": "UPSERT",                          
      "ResourceRecordSet": {
        "Name": "'"$RECORD_NAME"'",
        "Type": "A",
        "TTL": 1,
        "ResourceRecords": [
          {
            "Value": "'"$IP"'"
          }
        ]
      }
    }
  ]
}'
 # Action: upsert is to update existing values

done

 
END_TIME=$(date +%s)
TIME_TAKEN=$(($END_TIME - $START_TIME))
echo "time taken to execute script is $TIME_TAKEN"
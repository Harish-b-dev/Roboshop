#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SECURITY_ID="sg-0de4bc98ac346b345"
HOST_ID="Z04935093G1ODXCG494LF"
Record="learndaws88s.online"

for instance in $@
do
    INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SECURITY_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )
    
    if [ $instance == "frontend" ]; then
        IP=$( aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text )

        Record_name="$Record"
    else
        IP=$( aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
        --output text )

        Record_name="$instance.$Record"
    fi

    aws route53 change-resource-record-sets \
    --hosted-zone-id $HOST_ID \
    --change-batch '
    {
        "Comment": "Updating record",
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$Record_name'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
    }
    '

    echo "record updated for $instance, and IP is $IP"


    
done



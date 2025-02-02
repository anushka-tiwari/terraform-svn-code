import json
import boto3
import os
import time


# Initialize Boto3 clients
ec2_client = boto3.client('ec2')
route53_client = boto3.client('route53')
dynamodb_client = boto3.client('dynamodb')

# Retrieve environment variables
hosted_zone_id = os.environ['HOSTED_ZONE_ID']
domain_name = os.environ['DOMAIN_NAME']
dynamodb_table_name = os.environ['DYNAMODB_TABLE_NAME']
environment = os.environ.get('ENVIRONMENT', 'cab')  

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event, indent=2)}")
    
    # Extract instance ID and detail type
    instance_id = event['detail']['EC2InstanceId']
    detail_type = event['detail-type']
    
    if detail_type == 'EC2 Instance Launch Successful':
        register_instance(instance_id)
    elif detail_type == 'EC2 Instance Terminate Successful':
        deregister_instance(instance_id)
    else:
        print("Event detail-type not supported.")

def wait_for_instance_ready(instance_id):
   
        time.sleep(200)  # Wait for 10 seconds before checking again

def register_instance(instance_id):
    try:
        # Wait for the instance to be fully running and ready for SSM
        wait_for_instance_ready(instance_id)
        # Get the private IP address and Name tag of the instance
        response = ec2_client.describe_instances(InstanceIds=[instance_id])
        instance = response['Reservations'][0]['Instances'][0]
        private_ip = instance['PrivateIpAddress']
       
        name_tag = next(tag['Value'] for tag in instance['Tags'] if tag['Key'] == 'Hostname')

        
        # Continue with the rest of your logic using private_ip and name_tag
        # ...

    except Exception as e:
        print(f"Error registering instance {instance_id}: {str(e)}")
        
        print(f"Private IP: {private_ip}, Name tag: {name_tag}")
        
        # Store instance details in DynamoDB
        dynamodb_client.put_item(
            TableName=dynamodb_table_name,
            Item={
                'InstanceId': {'S': instance_id},
                'NameTag': {'S': name_tag},
                'PrivateIp': {'S': private_ip}
            }
        )
        
        # Create the DNS record
        route53_client.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                'Changes': [
                    {
                        'Action': 'CREATE',
                        'ResourceRecordSet': {
                            'Name': f'{name_tag}.{domain_name}',
                            'Type': 'A',
                            'TTL': 60,
                            'ResourceRecords': [{'Value': private_ip}]
                        }
                    }
                ]
            }
        )
        print(f"DNS record created for {name_tag}.{domain_name} -> {private_ip}")
    except Exception as e:
        print(f"Error registering instance {instance_id}: {e}")

def deregister_instance(instance_id):
    try:
        # Retrieve instance details from DynamoDB
        response = dynamodb_client.get_item(
            TableName=dynamodb_table_name,
            Key={'InstanceId': {'S': instance_id}}
        )
        item = response.get('Item')
        if not item:
            print(f"No details found for instance {instance_id} in DynamoDB.")
            return
        
        name_tag = item['NameTag']['S']
        private_ip = item['PrivateIp']['S']
        
        # Delete the DNS record
        route53_client.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                'Changes': [
                    {
                        'Action': 'DELETE',
                        'ResourceRecordSet': {
                            'Name': f'{name_tag}.{domain_name}',
                            'Type': 'A',
                            'TTL': 60,
                            'ResourceRecords': [{'Value': private_ip}]
                        }
                    }
                ]
            }
        )
        print(f"DNS record deleted for {name_tag}.{domain_name}")
        
        # Delete the DynamoDB item
        dynamodb_client.delete_item(
            TableName=dynamodb_table_name,
            Key={'InstanceId': {'S': instance_id}}
        )
        print(f"Deleted DynamoDB entry for instance {instance_id}")
        
    except Exception as e:
        print(f"Error deregistering instance {instance_id}: {e}")

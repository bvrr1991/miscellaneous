import boto3
table_name = 'Orders'

params = {
'TableName': table_name,
'KeySchema': [
{'AttributeName': 'order_id', 'KeyType': 'HASH'}
          
],
'AttributeDefinitions': [
{'AttributeName': 'order_id', 'AttributeType': 'S'}
],
'ProvisionedThroughput': {
'ReadCapacityUnits': 10,
'WriteCapacityUnits': 10
 }
 }
dyn=boto3.resource('dynamodb',region_name='us-east-1')

table = dyn.create_table(**params)
print(f"Creating {table_name}...")
table.wait_until_exists()
print(table)
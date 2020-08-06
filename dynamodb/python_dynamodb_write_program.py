import boto3
import pandas as pd
import csv
import decimal
s3=boto3.resource("s3")
obj = s3.Object(bucket_name='venky2020', key='retail.csv')
body = obj.get()['Body'].read()
reader = csv.reader(body.decode('utf-8').split('\r\n'))
dynamodb = boto3.resource('dynamodb','us-east-1')
table = dynamodb.Table('Orders')
header=next(reader)
for i in reader:
  invoice = i[0]
  customer = int(i[6])
  orderDate = i[4]
  quantity = i[3]
  description = i[2]
  unitPrice = i[5]
  country = i[7].rstrip()
  stockCode = i[1]
  orderID = invoice + "-" + stockCode
  response = table.put_item(
  Item = {
  'order_id':orderID,
 'CustomerID': decimal.Decimal(customer),
 'OrderDate': orderDate,
 'Quantity': decimal.Decimal(quantity),
 'UnitPrice': decimal.Decimal(unitPrice),
 'Description': description,
 'Country': country
 }
 )







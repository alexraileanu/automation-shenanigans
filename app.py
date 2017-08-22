from flask import Flask
from flask_redis import FlaskRedis
import time
import uuid
import boto3

app = Flask(__name__)
app.config.from_pyfile('config/echo.cfg')

@app.route('/<echo>')
def echo(echo):
    dynamodb = boto3.resource('dynamodb')

    data = {'id': str(uuid.uuid4()), 'q': echo, 'date': str(time.time())}

    table = dynamodb.Table('echo')
    table.put_item(Item=data)
    
    return echo
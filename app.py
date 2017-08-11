from flask import Flask
from flask_redis import FlaskRedis
import time
import uuid

app = Flask(__name__)
app.config.from_pyfile('config/echo.cfg')

redis = FlaskRedis(app)

@app.route('/<echo>')
def echo(echo):
    redis_stuff = {'id': str(uuid.uuid4()), 'q': echo, 'date': time.time()}
    redis.lpush('echo', redis_stuff)
    return echo
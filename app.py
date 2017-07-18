from flask import Flask

app = Flask(__name__)

@app.route('/<echo>')
def echo(echo):
    return echo
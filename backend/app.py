from flask import Flask
import os
import mysql.connector

app = Flask(__name__)

@app.route('/health')
def health():
    return 'OK'

@app.route('/db')
def db_connect():
    try:
        conn = mysql.connector.connect(
            host=os.environ.get("DB_HOST", "mysql"),
            user=os.environ.get("DB_USER", "root"),
            password=os.environ.get("DB_PASSWORD", "example"),
            database=os.environ.get("DB_NAME", "test")
        )
        return "Connected to MySQL!"
    except Exception as e:
        return f"DB connection failed: {e}", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

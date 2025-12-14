#!/bin/bash
# Ensure correct locale for Python, Flask and MySQL operations
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

########################################
# Update system & install Python
########################################
apt update -y
apt install -y python3 python3-pip

# Install Flask (web framework), Boto3 (AWS SDK), and MySQL connector
pip3 install flask boto3 mysql-connector-python

########################################
# Export RDS connection details for the Flask app
########################################
echo "RDS_HOST=${db_endpoint}" >> /etc/environment
echo "RDS_USER=${db_username}" >> /etc/environment
echo "RDS_PASS=${db_password}" >> /etc/environment
echo "RDS_NAME=mvp" >> /etc/environment

# Load variables into current shell
source /etc/environment

################################################################################
# INSTALL MYSQL CLIENT AND CREATE DB/TABLE 
################################################################################

# Install MySQL client on the EC2 instance
apt install -y mysql-client-core-8.0

# Wait until RDS is reachable
echo "Waiting for RDS to become ready..."
until mysql -h "${db_endpoint}" -u "${db_username}" -p"${db_password}" -e "SELECT 1;" >/dev/null 2>&1; do
  echo "RDS not ready yet... retrying in 5s"
  sleep 5
done
echo "RDS is ready!"

# Create database and table inside RDS
mysql -h "${db_endpoint}" -u "${db_username}" -p"${db_password}" <<EOF
CREATE DATABASE IF NOT EXISTS mvp;
USE mvp;
CREATE TABLE IF NOT EXISTS uploads (
    id INT AUTO_INCREMENT PRIMARY KEY,
    filename VARCHAR(255),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

########################################
# Create application directory
########################################
mkdir -p /opt/mvp_app

########################################
# Create Flask application
########################################
cat <<EOF > /opt/mvp_app/app.py
from flask import Flask, request, send_file
import boto3
import os
import mysql.connector

# Load RDS credentials via environment
RDS_HOST = os.getenv("RDS_HOST")
RDS_USER = os.getenv("RDS_USER")
RDS_PASS = os.getenv("RDS_PASS")
RDS_NAME = os.getenv("RDS_NAME")

def get_db_connection():
    return mysql.connector.connect(
        host=RDS_HOST,
        user=RDS_USER,
        password=RDS_PASS,
        database=RDS_NAME
    )

BUCKET = "${bucket_name}"

app = Flask(__name__)
s3 = boto3.client("s3")

@app.route("/")
def home():
    return """
    <html>
    <head>
        <title>Terraform + AWS MVP</title>
        <style>
            body {
                background-color: #2a5298;
                color: white;
                text-align: center;
                font-family: Arial;
                padding-top: 10%;
            }
            a { color: cyan; font-size: 22px; }
        </style>
    </head>
    <body>
        <h1>Terraform + AWS MVP</h1>
        <p>This page is served automatically by an EC2 instance provisioned via Terraform.</p>
        <p>Created by Athanasios Oikonomopoulos</p>
        <p>Microservice running at: <b>/upload</b> and <b>/download</b></p>
        <br>
        <a href="/upload">Upload File</a><br><br>
        <a href="/download">Download File</a>
    </body>
    </html>
    """

@app.route("/upload", methods=["GET", "POST"])
def upload():
    if request.method == "POST":
        file = request.files["file"]

        # Upload to S3
        s3.upload_fileobj(file, BUCKET, file.filename)

        # Log into RDS
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("INSERT INTO uploads (filename) VALUES (%s)", (file.filename,))
            conn.commit()
            cursor.close()
            conn.close()
        except Exception as e:
            return f"Upload succeeded but database insert failed: {str(e)}"

        return f"File '{file.filename}' uploaded and logged into RDS!"

    return """
    <h2>Upload file to S3</h2>
    <form method="POST" enctype="multipart/form-data">
        <input type="file" name="file">
        <input type="submit" value="Upload">
    </form>
    """

@app.route("/download", methods=["GET"])
def download():
    filename = request.args.get("file")

    if not filename:
        return """
        <h2>Download file from S3</h2>
        <form>
            File name: <input name="file">
            <input type="submit" value="Download">
        </form>
        """

    local_path = f"/tmp/{filename}"

    try:
        s3.download_file(BUCKET, filename, local_path)
        return send_file(local_path, as_attachment=True)
    except Exception as e:
        return f"Error: {str(e)}"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
EOF

########################################
# Create systemd service for Flask app
########################################
cat <<EOF > /etc/systemd/system/mvp.service
[Unit]
Description=Flask MVP Microservice
After=network.target

[Service]
EnvironmentFile=/etc/environment
Environment="RDS_HOST=${db_endpoint}"
Environment="RDS_USER=${db_username}"
Environment="RDS_PASS=${db_password}"
Environment="RDS_NAME=mvp"
ExecStart=/usr/bin/python3 /opt/mvp_app/app.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon and start service
systemctl daemon-reload
systemctl enable mvp.service
systemctl start mvp.service

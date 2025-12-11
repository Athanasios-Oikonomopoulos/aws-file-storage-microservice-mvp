#!/bin/bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

apt update -y
apt install -y python3 python3-pip

pip3 install flask boto3

# Create application directory
mkdir -p /opt/mvp_app

########################################
# Create Flask application
########################################
cat <<EOF > /opt/mvp_app/app.py
from flask import Flask, request, send_file, render_template_string
import boto3
import os

BUCKET = "${bucket_name}"

app = Flask(__name__)
s3 = boto3.client("s3")

# Homepage
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

# Upload form + handler
@app.route("/upload", methods=["GET", "POST"])
def upload():
    if request.method == "POST":
        file = request.files["file"]
        s3.upload_fileobj(file, BUCKET, file.filename)
        return f"File '{file.filename}' uploaded to S3 bucket {BUCKET}!"

    return """
    <h2>Upload file to S3</h2>
    <form method="POST" enctype="multipart/form-data">
        <input type="file" name="file">
        <input type="submit" value="Upload">
    </form>
    """

# Download file by name
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
ExecStart=/usr/bin/python3 /opt/mvp_app/app.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Enable + start the service
systemctl daemon-reload
systemctl enable mvp.service
systemctl start mvp.service

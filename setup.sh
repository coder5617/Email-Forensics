#!/bin/bash
PROJECT_DIR="MailForensics"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR
touch app.py
touch requirements.txt
mkdir -p templates
touch templates/index.html
touch templates/results.html
mkdir -p static/css
touch static/css/style.css
touch Dockerfile
touch docker-compose.yml
touch .env
cd ..
echo "File structure created. Now copy the provided code into each file as instructed."

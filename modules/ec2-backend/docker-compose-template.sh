#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y docker.io

sudo systemctl start docker
sudo systemctl enable docker

# Add EC2 user to docker group
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "DB_HOST=${DB_HOST}"
echo "DB_USERNAME=${DB_USER}"
echo "DB_PASSWORD=${DB_PASSWORD}"
echo "DB_NAME=${DB_NAME}"
echo "PORT=${PORT}"
echo "NODE_ENV=${NODE_ENV}"
echo "ACCESS_TOKEN_SECRET=${ACCESS_TOKEN_SECRET}"
echo "REFRESH_TOKEN_SECRET=${REFRESH_TOKEN_SECRET}"

# Create Docker Compose file dynamically with passed environment variables
cat <<EOL > docker-compose.yml
version: '3'
services:
  app:
    image: anrajiv/matchmyresume-backend:latest
    environment:
      - DB_HOST=${DB_HOST}
      - DB_USERNAME=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_NAME=${DB_NAME}
      - PORT=${PORT}
      - NODE_ENV=${NODE_ENV}
      - ACCESS_TOKEN_SECRET=${ACCESS_TOKEN_SECRET}
      - REFRESH_ACCESS_TOKEN=${REFRESH_TOKEN_SECRET}
    ports:
      - "5555:5555"
EOL

# Run Docker Compose
sudo docker-compose up -d

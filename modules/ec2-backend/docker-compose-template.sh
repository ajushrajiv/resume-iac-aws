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

# Create Docker Compose file dynamically with passed environment variables
cat <<EOL > docker-compose.yml
version: '3'
services:
  app:
    image: anrajiv/matchmyresume-backend:latest
    environment:
      - DB_HOST=resume-db-instance.cnextk3vsye6.eu-central-1.rds.amazonaws.com
      - DB_USERNAME=root
      - DB_PASSWORD=root1234
      - DB_NAME=matchmyresume_app
      - PORT=5555
      - NODE_ENV=dev
      - ACCESS_TOKEN_SECRET=fa4f23c147cffde4334becb17c3aaf9eb0e9e567390ecbf8d337e6ce77ef5577e74a16e5aa22b6fdd178521df96f213276962a22a337b90f39e54dd5a6e0e1da
      - REFRESH_ACCESS_TOKEN=9575187335cea5ab4794ac8bba0e5c2b53cd25d8cf6f3751da50282fc0cd47c15e2e69106123e3c0345059985008f7bc700192962480170c34abb7614727a916
    ports:
      - "5555:5555"
EOL

# Run Docker Compose
sudo docker-compose up -d

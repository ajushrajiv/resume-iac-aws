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

echo "$DOCKER_PASSWORD" | sudo docker login --username "$DOCKER_USERNAME" --password-stdin

echo "NEXT_PUBLIC_WEBSOCKET_URL=${NEXT_PUBLIC_WEBSOCKET_URL}"
echo "NEXT_PUBLIC_API_HOST=${NEXT_PUBLIC_API_HOST}"

# Create Docker Compose file dynamically with passed environment variables
cat <<EOL > docker-compose.yml
version: '3'
services:
  app:
    image: anrajiv/demo-matchmyresume-frontend-elb-healthcheck:new-version-one
    environment:
      - NEXT_PUBLIC_WEBSOCKET_URL=${NEXT_PUBLIC_WEBSOCKET_URL}
      - NEXT_PUBLIC_API_HOST=${NEXT_PUBLIC_API_HOST}
    ports:
      - "3000:3000"
EOL

# Run Docker Compose
sudo docker-compose up -d

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "matchmyresume-backend-state-demo--0788da0f74"
    key    = "matchmyresume-backend-state-demo--0788da0f74/vpc/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_db_subnet_group" "resume_subnet_group" {
  name = "container-subnet-group"
  subnet_ids = [
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1a,
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1b,
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1c
  ]
}

data "terraform_remote_state" "rds-sql" {
  backend = "s3"
  config = {
    bucket = "matchmyresume-backend-state-demo--0788da0f74"
    key    = "matchmyresume-backend-state-demo--0788da0f74/rds-sql/terraform.tfstate"
    region = "eu-central-1"
  }
}

output "rds_endpoint" {
  value = data.terraform_remote_state.rds-sql.outputs.rds_endpoint
}

resource "aws_security_group" "ec2_backend_sg" {
  name   = "ec2-backend-sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [
      data.terraform_remote_state.vpc.outputs.private_subnet_cidr_block_1a,
      data.terraform_remote_state.vpc.outputs.private_subnet_cidr_block_1b,
      data.terraform_remote_state.vpc.outputs.private_subnet_cidr_block_1c
    ]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_ec2_backend_to_rds" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.rds-sql.outputs.rds_security_group_id
  source_security_group_id = aws_security_group.ec2_backend_sg.id
}

resource "aws_instance" "backend_instance" {
  ami             = "ami-0e04bcbe83a83792e"
  instance_type   = "t2.micro"
  key_name        = "test-keypair"
  subnet_id       = data.terraform_remote_state.vpc.outputs.public_subnet_id_1a
  security_groups = [aws_security_group.ec2_backend_sg.id]

  tags = {
    Name = "Docker-EC2-Instance"
  }

  user_data = <<-EOF
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
          - DB_HOST=${DB_HOST}
          - DB_USERNAME=${DATABASE_USER}
          - DB_PASSWORD=${DATABASE_PASSWORD}
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
  EOF
}

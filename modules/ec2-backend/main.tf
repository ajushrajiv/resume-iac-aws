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

output "rds_private_address" {
  value = data.terraform_remote_state.rds-sql.outputs.rds_private_address
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
    from_port   = 5555
    to_port     = 5555
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

  ingress {
    from_port   = 5555
    to_port     = 5555
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

data "template_file" "user_data" {
  template = file("${path.module}/docker-compose-template.sh")

  vars = {
    DB_HOST              = data.terraform_remote_state.rds-sql.outputs.rds_private_address.value
    DB_USER              = var.db_user
    DB_PASSWORD          = var.db_password
    DB_NAME              = var.db_name
    PORT                 = var.port
    NODE_ENV             = var.node_env
    ACCESS_TOKEN_SECRET  = var.access_token
    REFRESH_TOKEN_SECRET = var.refresh_token
  }
}

resource "aws_instance" "backend_instance" {
  ami             = "ami-0e04bcbe83a83792e"
  instance_type   = "t2.small"
  key_name        = "test-keypair"
  subnet_id       = data.terraform_remote_state.vpc.outputs.public_subnet_id_1a
  security_groups = [aws_security_group.ec2_backend_sg.id]

  tags = {
    Name = "Docker-EC2-Instance"
  }

  user_data = data.template_file.user_data.rendered
}

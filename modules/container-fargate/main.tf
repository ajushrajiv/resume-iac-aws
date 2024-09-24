data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "matchmyresume-backend-state-demo--0788da0f74"
    key    = "matchmyresume-backend-state-demo--0788da0f74/vpc/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_db_subnet_group" "resume_subnet_group" {
  name = "rds-subnet-group"
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

output "rds_private_ip" {
  value = data.terraform_remote_state.rds-sql.outputs.rds_private_ip
}

resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.private_subnet_cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




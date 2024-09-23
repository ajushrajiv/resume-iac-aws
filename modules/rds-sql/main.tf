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
    data.terraform_remote_state.vpc.outputs.private_subnet_id_1a,
    data.terraform_remote_state.vpc.outputs.private_subnet_id_1b,
    data.terraform_remote_state.vpc.outputs.private_subnet_id_1c
  ]
}

resource "aws_security_group" "resume_sg" {
  name        = "rds-sg"
  description = "Allow access to RDS"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_db_instance" "resume_db_instance" {
  identifier          = "resume-db-instance"
  instance_class      = "db.t2.micro" 
  engine              = "mysql"       
  engine_version      = "8.0.23"      
  allocated_storage   = 20            
  db_name                 = "matchmyresume_app"
  username            = var.db_master_username
  password            = var.db_master_password
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.resume_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.resume_subnet_group.name
  multi_az            = false         
  backup_retention_period = 7         
  skip_final_snapshot = true         
}

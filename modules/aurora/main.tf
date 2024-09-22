data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "matchmyresume-backend-state-demo--0788da0f74"
    key    = "matchmyresume-backend-state-demo--0788da0f74/vpc/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_db_subnet_group" "resume_subnet_group" {
  name = "aurora-subnet-group"
  subnet_ids = [
    data.terraform_remote_state.vpc.outputs.private_subnet_id_1a,
    data.terraform_remote_state.vpc.outputs.private_subnet_id_1b,
    data.terraform_remote_state.vpc.outputs.private_subnet_id_1c
  ]
}

resource "aws_security_group" "resume_sg" {
  name        = "aurora-sg"
  description = "Allow access to Aurora"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_rds_cluster_instance" "resume_aurora_instance" {
  count               = 2
  identifier          = "aurora-instance-1-${count.index}"
  cluster_identifier  = aws_rds_cluster.resume_aurora_cluster.id
  instance_class      = "db.t2"
  engine              = aws_rds_cluster.resume_aurora_cluster.engine
  engine_version      = aws_rds_cluster.resume_aurora_cluster.engine_version
  publicly_accessible = false
}

resource "aws_rds_cluster" "resume_aurora_cluster" {
  engine                 = "aurora-mysql"
  cluster_identifier     = "my-aurora-cluster"
  database_name          = "matchmyresumedb"
  master_username        = var.db_master_username
  master_password        = var.db_master_password
  vpc_security_group_ids = [aws_security_group.resume_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.resume_subnet_group.name
}

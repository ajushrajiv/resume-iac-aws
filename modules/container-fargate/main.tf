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
}

resource "aws_ecs_task_definition" "resume_task" {
  family                   = "resume-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "resume-backend"
      image     = var.ecr_image_url
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DB_HOST"
          value = data.terraform_remote_state.rds-sql.outputs.rds_private_ip
        },
        {
          name  = "DATABASE_USER"
          value = var.db_user
        },
        {
          name  = "DATABASE_PASSWORD"
          value = var.db_password
        },
        {
          name  = "DATABASE_NAME"
          value = data.terraform_remote_state.rds-sql.outputs.rds_db_name
        },
        {
          name  = "PORT"
          value = var.port
        },
        {
          name  = "NODE_ENV"
          value = var.node_env
        },
        {
          name  = "ACCESS_TOKEN_SECRET"
          value = var.access_token
        },
        {
          name  = "REFRESH_ACCESS_TOKEN"
          value = var.refresh_token
        },
      ]
    }
  ])
}

resource "aws_ecs_cluster" "resume_cluster" {
  name = "resume-cluster"
  tags = {
    Name = "resume-cluster"
  }
}

resource "aws_ecs_service" "resume_service" {
  name            = "resume-service"
  cluster         = aws_ecs_cluster.resume_cluster.id
  task_definition = aws_ecs_task_definition.resume_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets = [
      data.terraform_remote_state.vpc.outputs.public_subnet_id_1a,
      data.terraform_remote_state.vpc.outputs.public_subnet_id_1b,
      data.terraform_remote_state.vpc.outputs.public_subnet_id_1c
    ]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}




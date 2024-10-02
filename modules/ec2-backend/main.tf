data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "matchmyresume-backend-state-demo--0788da0f74"
    key    = "matchmyresume-backend-state-demo--0788da0f74/vpc/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_db_subnet_group" "resume_subnet_group" {
  name = "ec2-subnet-group"
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

output "rds_db_name" {
  value = data.terraform_remote_state.rds-sql.outputs.rds_db_name
}

resource "aws_security_group" "elb_asg_backend_sg" {
  name   = "elb-asg-backend-sg"
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
    protocol    = "tcp"
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
  source_security_group_id = aws_security_group.elb_asg_backend_sg.id
}

resource "aws_security_group_rule" "allow_lb_to_backend" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elb_asg_backend_sg.id
  source_security_group_id = aws_security_group.elb_asg_backend_sg.id
}


data "template_file" "user_data" {
  template = file("${path.module}/docker-compose-template.sh")

  vars = {
    DB_HOST              = data.terraform_remote_state.rds-sql.outputs.rds_private_address
    DB_USER              = var.db_user
    DB_PASSWORD          = var.db_password
    DB_NAME              = data.terraform_remote_state.rds-sql.outputs.rds_db_name
    PORT                 = var.port
    NODE_ENV             = var.node_env
    ACCESS_TOKEN_SECRET  = var.access_token
    REFRESH_TOKEN_SECRET = var.refresh_token
    LOG_LEVEL            = var.log_level
  }
}

resource "aws_lb" "resume_backend_lb" {
  name               = "resume-backend-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_asg_backend_sg.id]
  subnets = [
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1a,
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1b,
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1c
  ]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "resume_backend_tg" {
  name        = "resume-backend-target-group"
  port        = 5555
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  target_type = "instance"

  health_check {
    path                = "/v1/health/healthcheck"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "resume_backend_listener" {
  load_balancer_arn = aws_lb.resume_backend_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.resume_backend_tg.arn
  }
}

resource "aws_launch_template" "backend_launch_template" {
  name_prefix   = "backend-launch-template"
  image_id      = "ami-0e04bcbe83a83792e"
  instance_type = "t2.small"
  key_name      = "test-keypair"

  user_data = base64encode(data.template_file.user_data.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Docker-Backend-ASG"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.elb_asg_backend_sg.id]
    subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnet_id_1a
  }
}

resource "aws_autoscaling_group" "backend_asg" {
  desired_capacity = 2
  max_size         = 2
  min_size         = 2
  vpc_zone_identifier = [
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1a,
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1b
  ]

  launch_template {
    id      = aws_launch_template.backend_launch_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.resume_backend_tg.arn]

  tag {
    key                 = "Name"
    value               = "Backend-ASG-Instance"
    propagate_at_launch = true
  }
}

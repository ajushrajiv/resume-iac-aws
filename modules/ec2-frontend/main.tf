data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "matchmyresume-backend-state-demo--0788da0f74"
    key    = "matchmyresume-backend-state-demo--0788da0f74/vpc/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_db_subnet_group" "resume_subnet_group" {
  name = "ec2-frontend-subnet-group"
  subnet_ids = [
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1a,
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1b,
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1c
  ]
}

data "terraform_remote_state" "backend-ec2" {
  backend = "s3"
  config = {
    bucket = "matchmyresume-backend-state-demo--0788da0f74"
    key    = "matchmyresume-backend-state-demo--0788da0f74/backend-ec2/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_security_group" "elb_resume_frontend_asg" {
  name   = "elb-asg-frontend-sg"
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
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
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
    from_port   = 3000
    to_port     = 3000
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

resource "aws_security_group_rule" "allow_lb_to_frontend" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elb_resume_frontend_asg.id
  source_security_group_id = aws_security_group.elb_resume_frontend_asg.id
}


data "template_file" "user_data" {
  template = file("${path.module}/docker-compose-template.sh")

  vars = {
    NEXT_PUBLIC_WEBSOCKET_URL = "ws://${var.websocket_url}"
    NEXT_PUBLIC_API_HOST      = var.api_host
  }
}

resource "aws_lb" "resume_frontend_lb" {
  name               = "resume-frontend-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_resume_frontend_asg.id]
  subnets = [
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1a,
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1b,
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1c
  ]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "resume_frontend_tg" {
  name        = "resume-frontend-target-group"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  target_type = "instance"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "resume_frontend_listener" {
  load_balancer_arn = aws_lb.resume_frontend_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.resume_frontend_tg.arn
  }
}

resource "aws_launch_template" "frontend_launch_template" {
  name_prefix   = "frontend-launch-template"
  image_id      = "ami-0e04bcbe83a83792e"
  instance_type = "t2.small"
  key_name      = "test-keypair"

  user_data = base64encode(data.template_file.user_data.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Docker-Frontend-ASG"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.elb_resume_frontend_asg.id]
    subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnet_id_1a
  }
}

resource "aws_autoscaling_group" "frontend_asg" {
  desired_capacity = 2
  max_size         = 2
  min_size         = 2
  vpc_zone_identifier = [
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1a,
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1b
  ]

  launch_template {
    id      = aws_launch_template.frontend_launch_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.resume_frontend_tg.arn]

  tag {
    key                 = "Name"
    value               = "Frontend-ASG-Instance"
    propagate_at_launch = true
  }
}

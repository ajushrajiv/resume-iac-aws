data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "matchmyresume-backend-state-demo--0788da0f74"
    key    = "matchmyresume-backend-state-demo--0788da0f74/vpc/terraform.tfstate"
    region = "eu-central-1"
  }
}

locals {
  azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

resource "aws_iam_role" "ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_security_group" "resume_ec2_sg" {
  name        = "ec2-sg"
  description = "Allow traffic to EC2 instances"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_launch_configuration" "ec2_launch_config" {
  name          = "ec2-launch-config"
  image_id      = "ami-0e04bcbe83a83792e"
  instance_type = "t2.micro"

  security_groups = [aws_security_group.resume_ec2_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ec2_asg" {
  desired_capacity = 2
  max_size         = 2
  min_size         = 2
  vpc_zone_identifier = [
    data.terraform_remote_state.vpc.outputs.private_subnet_id_1a,
    data.terraform_remote_state.vpc.outputs.private_subnet_id_1b,
    data.terraform_remote_state.vpc.outputs.private_subnet_id_1c
  ]

  launch_configuration = aws_launch_configuration.ec2_launch_config.id

  tag {
    key                 = "test-keypair"
    value               = "matchmyresume-instance"
    propagate_at_launch = true
  }
}

resource "aws_elb" "web_elb" {
  name = "matchmyresume-elb"

  security_groups = [aws_security_group.resume_ec2_sg.id]

  subnets = [
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1a,
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1b,
    data.terraform_remote_state.vpc.outputs.public_subnet_id_1c
  ]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

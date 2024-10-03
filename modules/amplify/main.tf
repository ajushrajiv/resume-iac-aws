data "terraform_remote_state" "backend-ec2" {
  backend = "s3"
  config = {
    bucket = "matchmyresume-backend-state-demo--0788da0f74"
    key    = "matchmyresume-backend-state-demo--0788da0f74/backend-ec2/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_amplify_app" "matchmyresume_amplify_app" {
  name                = "matchmyresume"
  repository          = "https://github.com/ajushrajiv/resume-frontend"
  access_token        = var.access_token_repo
  
  platform            = "WEB"
  
  environment_variables = {
    _LIVE_UPDATES = "enabled"
    NEXT_PUBLIC_WEBSOCKET_URL = "ws://${data.terraform_remote_state.backend-ec2.outputs.load_balancer_dns}:5555"
  }

  enable_auto_branch_creation = true
  auto_branch_creation_patterns = [
    "*",
    "*/**",
  ]
  auto_branch_creation_config {
    enable_auto_build = true
  }
}

resource "aws_amplify_branch" "main_branch" {
  app_id       = aws_amplify_app.matchmyresume_amplify_app.id
  branch_name  = "development"

  enable_auto_build = true

  environment_variables = {
    NEXT_PUBLIC_WEBSOCKET_URL = "ws://${data.terraform_remote_state.backend-ec2.outputs.load_balancer_dns}:5555"
  }
}


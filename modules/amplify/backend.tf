terraform {
  backend "s3" {
    bucket = "matchmyresume-backend-state-demo--0788da0f74"
    key    = "resume-vpc-terraform-state/terraform.tfstate"
    region = "eu-central-1"
  }
}

terraform {
  backend "s3" {
    bucket = "matchmyresume-backend-state-demo-october14"
    key    = "resume-vpc-terraform-state/terraform.tfstate"
    region = "eu-central-1"
  }
}

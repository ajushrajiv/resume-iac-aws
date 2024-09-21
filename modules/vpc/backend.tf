terraform {
  backend "s3" {
    bucket = "matchmyresume-backend-state-demo--36c6460f31"
    key    = "resume-vpc-terraform-state/terraform.tfstate"
    region = "eu-central-1"
  }
}

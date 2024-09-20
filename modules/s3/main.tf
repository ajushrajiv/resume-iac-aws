resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  tags = {
    Name        = "resume-backend-state"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_versioning" "resume_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "access_policy_for_s3" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : { "AWS" : "arn:aws:iam::144130276541:root" },
        "Action" : "s3:ListBucket",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.terraform_state.bucket}"
      },
      {
        "Effect" : "Allow",
        "Principal" : { "AWS" : "arn:aws:iam::144130276541:root" },
        "Action" : ["s3:GetObject", "s3:PutObject"],
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.terraform_state.bucket}/*"
      }
    ]
  })
}



resource "aws_s3_bucket" "name1" {
  bucket = "terraform backend-2025"

  versioning {
    enabled = true
  }
}
terraform {
  backend "s3" {
    bucket = "terraform backend-2025"
    key = "terraform.tfstate"
    region = "eu-central-1"
    encrypt = true
  }
}
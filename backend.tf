resource "aws_s3_bucket" "name1" {
  bucket = "terraform backend"

  versioning {
    enabled = true
  }
}
terraform {
  backend "s3" {
    bucket = "terraform backend"
    key = "terraform.tfstate"
    region = "eu-central-1"
    encrypt = true
  }
}
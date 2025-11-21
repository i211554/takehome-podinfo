terraform {
  backend "s3" {
    bucket         = "i211554-s3-bucket"
    key            = "env/staging/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "i211554-state-locking"
  }
}

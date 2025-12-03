terraform {
  backend "s3" {
    bucket         = "my-terraform-states-1234"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

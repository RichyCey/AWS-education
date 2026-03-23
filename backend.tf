terraform {
  backend "s3" {
    bucket         = "my-app-tfstate-67735"
    key            = "prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

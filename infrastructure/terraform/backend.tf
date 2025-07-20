terraform {
  backend "s3" {
    bucket         = "between-laravel-multi-app-terraform-state-x3x2wdje"
    key            = "staging/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "between-laravel-multi-app-terraform-lock"
  }
}
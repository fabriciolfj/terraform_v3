provider "aws" {
  region = "us-east-2"
}


terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "fabricio211-terraform"
    key            = "workspaces-example/terraform.tfstate"
    region         = "us-east-2"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}


resource "aws_instance" "example" {
  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
}
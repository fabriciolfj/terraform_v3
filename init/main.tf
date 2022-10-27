provider "aws" {
  region = "sa-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-04b3c23ec8efcc2d6"
  instance_type = "t2.micro"

  tags = {
    Name = "terraform-example"
  }
}
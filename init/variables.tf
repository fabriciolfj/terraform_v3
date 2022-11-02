variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

#output "public_ip" {
#  value = aws_instance.example.public_ip
#  description = "ip publico do webserver"
#}
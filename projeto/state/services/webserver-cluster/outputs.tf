output "alb_dns_name" {
  value = aws_lb.example.dns_name
  description = "o dominio do load balaancer"
}
# terraform_v3

## Variavies de saida
- utilizandos variávies do tipo output, ideal para expor algum dado no console, como ip publico para uso por exemplo.
```
output "public_ip" {
  value = aws_instance.example.public_ip
  description = "ip publico do webserver"
}
```

## Consulta de recursos ao provedor
- consultar algum recurso já existente no provedor, para uso/vinculo há recursos que estamos criando
- podemos utilizar outros datas para filtros
```
data "aws_subnets" "default" {
  filter {
    name   = "vpc_id"
    values = [data.aws_vpc.default.id]
  }
}
```
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

## Implantando um loadbalance de exemplo
- loadbalance e dividido em 3 partes:
  - ouvinte
  - regras do ouvindo
  - gropo alvo
- em uma ordem de recursos, o elb apontando para um auto scaling group (asg), seria:
  - aws_lb (criação do elb)
  - aws_lb_listener (ouvinte) 
  - aws_lb_listener_rule (regras)
  - aws_lb_target_group (grupo de destino)
  - por fim, vincular ao asg:
````
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  max_size = 10
  min_size = 2

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "terraform-asg-example"
  }
}
`````

## Estado terraform
- mantem os registros dos recursos criados na nuvem
- compara com os recursos reais com os recursos registrados, afim de determinar quais alterações precisam ser aplicadas
- ideal que fique armazenado em um ambiente compartilhado, bloqueado/isolado.

### terraform backend-remote
- da suporte ao tfstate do terraform
- afim de suprir as situação salientadas acima
- por exemplo: podemos guardar em um s3 o arquivo de estado.

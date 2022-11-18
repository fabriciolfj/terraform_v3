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
- ideal que fique armazenado em um ambiente compartilhado, bloqueado e isolado.

### terraform backend-remote
- da suporte ao tfstate do terraform
- afim de suprir as situação salientadas acima
- por exemplo: podemos guardar em um s3 o arquivo de estado.

#### Detalhes do s3 que atende o backend-remote
- criamos um bucket
- configuramos o mesmo para versionamento, caso mudamos o nosso tfstate
- encriptmos seu armazenamento, via aws_s3_bucket_server_side_encryption_configuration
- podemos bloquear o acesso publico
- criamos uma tabela dynamodb para efetuar o lock do arquivo (evitar concorrência), ou seja, se você dar um apply e em seguida outro dev executar tambem um apply, ele esperará o seu comando concluir, para em seguida iniciar o dele.
- apos os procedimentos acima, crie um arquivo do backend conforme abaixo, e siga com os comandos no terraform:
```
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "fabricio211-terraform"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-2"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}
```
- uma limitação do backend está no uso de variáveis, onde não é permitido.
- outro ponto, quando se trabalha com módulos, devemos possuir um backend para cada módulo e este com key diferente entre si.

### Isolamento
- não podemos deixar toda a configuração em apenas um arquivo no terraform
- e cada ambiente ter sua configuração separada
- existem 2 meios, via workspace e layout de arquivo

#### workspace
- quando não especificado, os recursos são criados no workspace padrão
- os workspaces são isolados uns dos outros
- para mostrar o workspace, executamos o comando abaixo:
```
terraform workspace show
```
- para criar um novo workspace, executamos:
```
terraform workspace new example1
```
- para selecionar
```
terraform workspace list
terraform select example1
```

# A fonte de dados terraform_remote_state
- quando precisamos utilizar como fonte de dados, outro arquivo de estado terraform
- no exemplo abaixo, estamos utilizando o tfstate do recurso do banco de dados
```
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "terraform-up-and-running-state"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}
```
- em seguida utilizando-o
```
  user_data = templatefile("user-data.sh", {
              server_port = var.server_port
              db_address  = data.terraform_remote_state.db.outputs.address
              db_port     = data.terraform_remote_state.db.outputs.port
              })
```

## Dados sensíveis
- podemos passar valores de variávies de ambiente, desde que tenha o prefixo TF_VAR_nome da variavel configurada
- por exemplo:
```
variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
}
```
- para passar uma variável de ambiente para essa variavel seria:
```
$ export TF_VAR_db_username="root"
```
- o local aonde a variável e referenciada, não muda.

## Módulos
- caso queira reutilizar algum código no terraform, façamos o uso de módulos
- aonde colocamos nosso código de infra dentro deles, e podemos reutilizar em diversos ambientes.
- módulo consiste em arquivos de configurações do terraform, que podem ser referenciados, conforme abaixo:
```
module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster" (referenciado)

  (abaixo sao os parametros)
  cluster_name = "webservers-stage"
  db_remote_state_bucket = "fabricio211-terraform"
  db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 3
}
```

### Modificando módulos
- podemos passar variáveis como parâmetros, para que o módulo atenda o ambiente 
- caso queria utilizar variável no módulo, e não quer que seja modificada, use variavéis locais

### Dicas
- sempre evite blocos embutidos, no exemplo abaixo apartamos as regras de entrada e saida do security group.
```
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}
```
- caso no módulo esteja utilizando o templatefile, faça uso o path.modulo para atender a relatividade do caminho do arquivo.
```
  user_data = templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  })
```
- para fazer uso de algum id ou valor do módulo, utilize a sintaxe abaixo:
```
  autoscaling_group_name = module.webserver_cluster.asg_name
```

## Module Versioning
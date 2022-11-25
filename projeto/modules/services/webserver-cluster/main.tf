provider "aws" {
  region = "us-east-2"
}

resource "aws_launch_configuration" "example" {
  image_id         = var.ami
  instance_type    = var.instance_type
  security_groups  = [aws_security_group.instance.id]

  user_data = templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    server_text = var.server_text
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  })


  lifecycle { #caso mude, crio o novo, mantenho o antigo, quando o novo estiver ok, tira o antigo
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"
}

resource "aws_security_group_rule" "allow_server_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = var.server_port
  to_port     = var.server_port
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

resource "aws_security_group_rule" "allow_http_inbound2" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

moved { #quando for querer refatorar apenas o nome e nao excluir e recriar o recurso
  from = aws_security_group_rule.allow_http_inbound
  to   = aws_security_group_rule.allow_http_inbound2
}

resource "aws_autoscaling_group" "example" {
  name = var.cluster_name
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  max_size = var.max_size
  min_size = var.min_size

  instance_refresh {
    strategy = "Rolling" #tempo de inatividade zero
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.cluster_name}-asg-example"
  }

  dynamic "tag" {
    for_each = {
      for key, value in var.custom_tags:
          key => upper(value)
            if key != "NAME"
    }

    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_lb_target_group" "asg" {
  name     = "${var.cluster_name}-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_lb" "example" {
  name = "${var.cluster_name}-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = var.enable_autoscaling ? 1 : 0
  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 2
  max_size              = 3
  desired_capacity      = 3
  recurrence            = "0 9 * * *"

  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling? 1 : 0
  scheduled_action_name = "scale-in-at-night"
  min_size              = 2
  max_size              = 2
  desired_capacity      = 2
  recurrence            = "0 17 * * *"

  autoscaling_group_name = aws_autoscaling_group.example.name
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-2"
  }
}

module "internal_nodeport_elb" {

  count     = var.internal_elb.enabled ? 1 : 0
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 2.0"

  name = replace("${var.cluster_name}-internal-elb", "_", "-")

  subnets         = aws_subnet.cluster_private.*.id
  security_groups = [aws_security_group.internal_elb_sg[0].id]
  internal        = true

  listener = [
    {
      instance_port     = var.internal_elb.instance_port
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
    {
      instance_port     = var.internal_elb.instance_ssl_port
      instance_protocol = "HTTP"
      lb_port           = "443"
      lb_protocol       = "HTTPS"
      ssl_certificate_id = var.internal_elb.cert_arn
    },
  ]

  health_check = {
    target              = "HTTP:${var.internal_elb.instance_health_check_port}/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }
}

resource "aws_security_group" "internal_elb_sg" {
  count     = var.internal_elb.enabled ? 1 : 0
  name   = replace("${var.cluster_name}-internal-elb-sg", "_", "-")
  vpc_id = var.vpc_id

  ingress {
    description     = "internal access"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

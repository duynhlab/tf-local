locals {
  module_label = basename(abspath(path.module))
  default_tags = merge(var.tags, { TerraformModule = local.module_label })
}

# trivy:ignore:AVD-AWS-0053 Internet-facing by design (public web entrypoint); set var.internal=true for a private ALB.
resource "aws_lb" "this" {
  name                       = var.name
  load_balancer_type         = "application"
  internal                   = var.internal
  security_groups            = var.security_group_ids
  subnets                    = var.subnet_ids
  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  drop_invalid_header_fields = true

  tags = merge(local.default_tags, { Name = var.name })
}

# awsvpc network mode (ECS Fargate) registers targets by IP, so target_type = "ip".
resource "aws_lb_target_group" "this" {
  name                 = var.target_group_name
  port                 = var.target_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay

  health_check {
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = var.health_check_matcher
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = merge(local.default_tags, { Name = var.target_group_name })
}

# HTTP listener. When var.certificate_arn is set it redirects to HTTPS (prod);
# otherwise it forwards directly (lab / no ACM cert).
# trivy:ignore:AVD-AWS-0054 HTTP forward is the lab path (no ACM); set var.certificate_arn to enable HTTPS + redirect.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.certificate_arn == null ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
  }

  dynamic "default_action" {
    for_each = var.certificate_arn == null ? [] : [1]
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

# HTTPS listener — created only when an ACM certificate ARN is provided (real AWS).
resource "aws_lb_listener" "https" {
  count = var.certificate_arn == null ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

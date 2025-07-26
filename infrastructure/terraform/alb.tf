# Application Load Balancer

resource "aws_security_group_rule" "ecs_reverb_from_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow inbound traffic from ALB to ECS"
}

resource "aws_alb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.enable_deletion_protection

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ALB Target Groups
resource "aws_alb_target_group" "app" {
  name        = "${var.project_name}-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-app-tg"
  }
}

resource "aws_alb_target_group" "reverb" {
  name        = "${var.project_name}-reverb-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/up"
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-reverb-tg"
  }
}

# ALB Listeners
resource "aws_alb_listener" "app" {
  load_balancer_arn = aws_alb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app.arn
    type             = "forward"
  }

  tags = {
    Name = "${var.project_name}-app-alb-listener"
  }
}

# Host-based routing rule for Reverb subdomain
resource "aws_alb_listener_rule" "reverb_subdomain" {
  count        = var.certificate_arn != "" ? 1 : 0
  listener_arn = aws_alb_listener.https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.reverb.arn
  }

  condition {
    host_header {
      values = ["${var.reverb_subdomain}.${var.domain_name}"]
    }
  }

  tags = {
    Name = "${var.project_name}-reverb-rule"
  }
}


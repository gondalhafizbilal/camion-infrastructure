module "alb_access_logs" {
  source             = "../../../modules/s3"
  bucket_name        = "${var.backend_load_balancer.name}-alb-access"
  lifecycle_retain   = true
  access_logs_bucket = true
  versioning         = true
  retain_days        = 30
  delete_days        = 120
  tags               = var.common_tags
}

# ACM certificate for the ALB.
# Domain is managed in Hostinger — DNS validation records must be added manually.
# After running `terraform apply`, retrieve the CNAME records from the
# `alb_acm_validation_records` output and add them in Hostinger's DNS panel.
module "alb_acm_request_certificate" {
  source = "cloudposse/acm-request-certificate/aws"

  domain_name               = var.subdomain_name
  subject_alternative_names = ["*.${var.subdomain_name}"]
  validation_method         = "DNS"

  # Do not attempt to auto-create Route53 records — domain is in Hostinger.
  process_domain_validation_options = false

  # Do not block apply waiting for validation; add the CNAME records in Hostinger
  # and re-run once the certificate reaches ISSUED status.
  wait_for_certificate_issued = false

  ttl = "300"
}

# After apply, run: terraform output alb_acm_validation_records
# Add each record as a CNAME in Hostinger to complete certificate validation.
output "alb_acm_validation_records" {
  description = "CNAME records to add in Hostinger DNS to validate the ALB ACM certificate."
  value       = module.alb_acm_request_certificate.domain_validation_options
}

module "backend_load_balancer" {
  source = "../../../modules/load-balancer"

  name                       = var.backend_load_balancer.name
  load_balancer_type         = var.backend_load_balancer.type
  drop_invalid_header_fields = true
  enable_ssl                 = var.backend_load_balancer.enable_ssl
  internal                   = var.backend_load_balancer.internal
  vpc_id                     = module.vpc01.id
  subnets                    = values(module.vpc01.public_subnet_ids)
  enable_deletion_protection = var.backend_load_balancer.enable_deletion_protection
  idle_timeout               = var.backend_load_balancer.idle_timeout

  access_logs = {
    bucket = module.alb_access_logs.id
  }

  security_groups = [
    aws_security_group.loadbalancer_sg.id
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.alb_acm_request_certificate.arn
      action_type     = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "You have reached an invalid destination!"
        status_code  = "503"
      }
    }
  ]

  target_groups = [
    {
      name             = "backend-service"
      backend_protocol = var.backend_service.protocol
      backend_port     = var.backend_service.port
      target_type      = "ip"
      targets          = []
      health_check = {
        enabled             = var.backend_service.health_check_enabled
        path                = var.backend_service.health_check_path
        port                = "traffic-port"
        healthy_threshold   = var.backend_service.health_check_healthy_threshold
        unhealthy_threshold = var.backend_service.health_check_unhealthy_threshold
        timeout             = var.backend_service.health_check_timeout
        protocol            = var.backend_service.health_check_protocol
        matcher             = var.backend_service.health_check_matcher
      }
    },
    {
      name             = "frontend-service"
      backend_protocol = var.frontend_service.protocol
      backend_port     = var.frontend_service.port
      target_type      = "ip"
      targets          = []
      health_check = {
        enabled             = var.frontend_service.health_check_enabled
        path                = var.frontend_service.health_check_path
        port                = "traffic-port"
        healthy_threshold   = var.frontend_service.health_check_healthy_threshold
        unhealthy_threshold = var.frontend_service.health_check_unhealthy_threshold
        timeout             = var.frontend_service.health_check_timeout
        protocol            = var.frontend_service.health_check_protocol
        matcher             = var.frontend_service.health_check_matcher
      }
    },
    {
      name             = "dashboard-service"
      backend_protocol = var.dashboard_service.protocol
      backend_port     = var.dashboard_service.port
      target_type      = "ip"
      targets          = []
      health_check = {
        enabled             = var.dashboard_service.health_check_enabled
        path                = var.dashboard_service.health_check_path
        port                = "traffic-port"
        healthy_threshold   = var.dashboard_service.health_check_healthy_threshold
        unhealthy_threshold = var.dashboard_service.health_check_unhealthy_threshold
        timeout             = var.dashboard_service.health_check_timeout
        protocol            = var.dashboard_service.health_check_protocol
        matcher             = var.dashboard_service.health_check_matcher
      }
    },
    {
      name             = "chatbot-service"
      backend_protocol = var.chatbot_service.protocol
      backend_port     = var.chatbot_service.port
      target_type      = "ip"
      targets          = []
      health_check = {
        enabled             = var.chatbot_service.health_check_enabled
        path                = var.chatbot_service.health_check_path
        port                = "traffic-port"
        healthy_threshold   = var.chatbot_service.health_check_healthy_threshold
        unhealthy_threshold = var.chatbot_service.health_check_unhealthy_threshold
        timeout             = var.chatbot_service.health_check_timeout
        protocol            = var.chatbot_service.health_check_protocol
        matcher             = var.chatbot_service.health_check_matcher
      }
    },
    {
      name             = "image-service"
      backend_protocol = var.image_service.protocol
      backend_port     = var.image_service.port
      target_type      = "ip"
      targets          = []
      health_check = {
        enabled             = var.image_service.health_check_enabled
        path                = var.image_service.health_check_path
        port                = "traffic-port"
        healthy_threshold   = var.image_service.health_check_healthy_threshold
        unhealthy_threshold = var.image_service.health_check_unhealthy_threshold
        timeout             = var.image_service.health_check_timeout
        protocol            = var.image_service.health_check_protocol
        matcher             = var.image_service.health_check_matcher
      }
    },
    {
      name             = "product-translation-service"
      backend_protocol = var.product_translation_service.protocol
      backend_port     = var.product_translation_service.port
      target_type      = "ip"
      targets          = []
      health_check = {
        enabled             = var.product_translation_service.health_check_enabled
        path                = var.product_translation_service.health_check_path
        port                = "traffic-port"
        healthy_threshold   = var.product_translation_service.health_check_healthy_threshold
        unhealthy_threshold = var.product_translation_service.health_check_unhealthy_threshold
        timeout             = var.product_translation_service.health_check_timeout
        protocol            = var.product_translation_service.health_check_protocol
        matcher             = var.product_translation_service.health_check_matcher
      }
    }
  ]

  https_listener_rules = [
    {
      https_listener_index = 0
      priority             = 50
      actions = [
        {
          type               = "forward"
          target_group_index = 0
        }
      ]
      conditions = [
        {
          host_headers = [var.backend_service.host_header]
        }
      ]
    },
    {
      https_listener_index = 0
      priority             = 100
      actions = [
        {
          type               = "forward"
          target_group_index = 1
        }
      ]
      conditions = [
        {
          host_headers = [var.frontend_service.host_header]
        }
      ]
    },
    {
      https_listener_index = 0
      priority             = 150
      actions = [
        {
          type               = "forward"
          target_group_index = 2
        }
      ]
      conditions = [
        {
          host_headers = [var.dashboard_service.host_header]
        }
      ]
    },
    {
      https_listener_index = 0
      priority             = 200
      actions = [
        {
          type               = "forward"
          target_group_index = 3
        }
      ]
      conditions = [
        {
          host_headers = [var.chatbot_service.host_header]
        }
      ]
    },
    {
      https_listener_index = 0
      priority             = 250
      actions = [
        {
          type               = "forward"
          target_group_index = 4
        }
      ]
      conditions = [
        {
          host_headers = [var.image_service.host_header]
        }
      ]
    },
    {
      https_listener_index = 0
      priority             = 300
      actions = [
        {
          type               = "forward"
          target_group_index = 5
        }
      ]
      conditions = [
        {
          host_headers = [var.product_translation_service.host_header]
        }
      ]
    }
  ]

  tags = var.common_tags
}

# Output the ALB DNS name — create a CNAME record in Hostinger pointing your
# API hostname (e.g. api.camiontrading.com) to this value.
output "alb_dns_name" {
  description = "ALB DNS name — use as the CNAME target in Hostinger for your API hostname."
  value       = module.backend_load_balancer.lb_dns_name
}

resource "aws_security_group" "loadbalancer_sg" {
  name        = "${var.aws_profile}-alb-sg"
  description = "Allow HTTP and HTTPS inbound traffic from the internet"
  vpc_id      = module.vpc01.id

  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    {
      "Name" = "${var.aws_profile}-alb-SG"
    },
    var.common_tags
  )
}

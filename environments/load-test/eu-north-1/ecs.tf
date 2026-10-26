resource "aws_security_group" "runner" {
  name        = "load-test-k6-runner"
  description = "Egress-only SG for k6 driver tasks"
  vpc_id      = data.aws_vpc.host.id
  tags        = var.common_tags

  egress {
    description = "All outbound (target ALBs are public)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Dedicated cluster, kept separate from app clusters so a load-test mishap can't impact app autoscaling.
resource "aws_ecs_cluster" "runner" {
  name = "load-test-k6-runner"
  tags = var.common_tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "runner" {
  cluster_name       = aws_ecs_cluster.runner.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 0
  }
}

# Task definition is parameterized via env vars supplied at `aws ecs run-task` time
# (RUN_ID, TASK_INDEX, TASK_COUNT, VUS, DURATION, TARGET_*). That keeps one task def reusable.
resource "aws_ecs_task_definition" "runner" {
  family                   = "load-test-k6-runner"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.runner.cpu
  memory                   = var.runner.memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn
  tags                     = var.common_tags

  container_definitions = jsonencode([{
    name      = "k6"
    image     = "${module.k6_runner_ecr.repository_url}:latest"
    essential = true
    environment = [
      { name = "RESULTS_BUCKET", value = aws_s3_bucket.results.bucket },
      { name = "DEFAULT_VUS", value = tostring(var.runner.vus_per_task) },
      { name = "DEFAULT_DURATION", value = var.runner.duration },
      { name = "TARGET_FRONTEND", value = var.default_target_base_urls.frontend },
      { name = "TARGET_BACKEND", value = var.default_target_base_urls.backend },
      { name = "TARGET_IMAGE_SERVICE", value = var.default_target_base_urls.image_service },
      { name = "TARGET_CHATBOT", value = var.default_target_base_urls.chatbot },
      { name = "TARGET_PRODUCT_TRANSLATION", value = var.default_target_base_urls.product_translation },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.runner.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "k6"
      }
    }
  }])
}

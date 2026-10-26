resource "aws_cloudwatch_log_group" "runner" {
  name              = "/ecs/load-test/k6-runner"
  retention_in_days = 14
  tags              = var.common_tags
}

output "ecr_repository_url" {
  description = "Push the runner image here: docker push <url>:latest"
  value       = module.k6_runner_ecr.repository_url
}

output "cluster_name" {
  value = aws_ecs_cluster.runner.name
}

output "task_definition_family" {
  value = aws_ecs_task_definition.runner.family
}

output "results_bucket" {
  value = aws_s3_bucket.results.bucket
}

output "log_group" {
  value = aws_cloudwatch_log_group.runner.name
}

output "subnet_ids" {
  value = data.aws_subnets.private.ids
}

output "security_group_id" {
  value = aws_security_group.runner.id
}

output "run_command_hint" {
  description = "Convenience — call ../../../load-tests/run.sh with these outputs sourced as env vars."
  value       = <<-EOT
    export LT_CLUSTER=${aws_ecs_cluster.runner.name}
    export LT_TASK_DEF=${aws_ecs_task_definition.runner.family}
    export LT_BUCKET=${aws_s3_bucket.results.bucket}
    export LT_SUBNETS=${join(",", data.aws_subnets.private.ids)}
    export LT_SG=${aws_security_group.runner.id}
    cd ../../../load-tests && ./run.sh
  EOT
}

output "id" {
  description = "ARN that identifies the service"
  value       = try(aws_ecs_service.this[0].id, aws_ecs_service.ignore_task_definition[0].id, null)
}

output "name" {
  description = "Name of the service"
  value       = try(aws_ecs_service.this[0].name, aws_ecs_service.ignore_task_definition[0].name, null)
}

output "iam_role_name" {
  description = "Service IAM role name"
  value       = try(aws_iam_role.service[0].name, null)
}

output "iam_role_arn" {
  description = "Service IAM role ARN"
  value       = try(aws_iam_role.service[0].arn, null)
}

output "iam_role_unique_id" {
  description = "Stable and unique string identifying the service IAM role"
  value       = try(aws_iam_role.service[0].unique_id, null)
}

output "container_definitions" {
  description = "Container definitions"
  value       = module.container_definition
}

output "task_definition_arn" {
  description = "Full ARN of the Task Definition (including both `family` and `revision`)"
  value       = try(aws_ecs_task_definition.this[0].arn, null)
}

output "task_definition_revision" {
  description = "Revision of the task in a particular family"
  value       = try(aws_ecs_task_definition.this[0].revision, null)
}

output "task_definition_family" {
  description = "The unique name of the task definition"
  value       = try(aws_ecs_task_definition.this[0].family, null)
}

output "task_exec_iam_role_name" {
  description = "Task execution IAM role name"
  value       = try(aws_iam_role.task_exec[0].name, null)
}

output "task_exec_iam_role_arn" {
  description = "Task execution IAM role ARN"
  value       = try(aws_iam_role.task_exec[0].arn, null)
}

output "task_exec_iam_role_unique_id" {
  description = "Stable and unique string identifying the task execution IAM role"
  value       = try(aws_iam_role.task_exec[0].unique_id, null)
}
  
output "tasks_iam_role_name" {
  description = "Tasks IAM role name"
  value       = try(aws_iam_role.tasks[0].name, null)
}

output "tasks_iam_role_arn" {
  description = "Tasks IAM role ARN"
  value       = try(aws_iam_role.tasks[0].arn, null)
}

output "tasks_iam_role_unique_id" {
  description = "Stable and unique string identifying the tasks IAM role"
  value       = try(aws_iam_role.tasks[0].unique_id, null)
}

output "autoscaling_policies" {
  description = "Map of autoscaling policies and their attributes"
  value       = aws_appautoscaling_policy.this
}

output "autoscaling_scheduled_actions" {
  description = "Map of autoscaling scheduled actions and their attributes"
  value       = aws_appautoscaling_scheduled_action.this
}

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = try(aws_security_group.this[0].arn, null)
}

output "security_group_id" {
  description = "ID of the security group"
  value       = try(aws_security_group.this[0].id, null)
}

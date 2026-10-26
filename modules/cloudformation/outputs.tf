output "id" {
  description = "A unique identifier of the stack."
  value       = length(aws_cloudformation_stack.this) > 0 ? aws_cloudformation_stack.this[0].id : null
}

output "outputs" {
  description = "A map of outputs from the stack."
  value       = length(aws_cloudformation_stack.this) > 0 ? aws_cloudformation_stack.this[0].outputs : {}
}

output "tags_all" {
  description = "A map of tags assigned to the resource, including those inherited from the provider default_tags configuration block."
  value       = length(aws_cloudformation_stack.this) > 0 ? aws_cloudformation_stack.this[0].tags_all : {}
}

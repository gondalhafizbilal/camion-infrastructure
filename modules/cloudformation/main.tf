resource "aws_cloudformation_stack" "this" {
  name          = var.stack_name
  
  count = var.template_path != null && var.template_path != "" ? 1 : var.template_url != null && var.template_url != "" ? 1 : 0

  template_body = var.template_path != null && var.template_path != "" ? file(var.template_path) : null
  template_url  = var.template_url != null && var.template_url != "" ? var.template_url : null
  parameters         = var.parameters
  capabilities       = var.capabilities
  disable_rollback   = var.disable_rollback
  on_failure         = var.on_failure
  timeout_in_minutes = var.timeout_in_minutes
  tags = merge(var.tags, { "Name" = var.stack_name })
}

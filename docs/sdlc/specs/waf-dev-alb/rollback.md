# Rollback — WAFv2 (count mode) on the dev ALB

**Blast radius: zero.** Every rule is count-only, so the ALB serves identically with or
without the web ACL. Rolling back removes monitoring, not protection.

## Options (least → most invasive)
1. **Detach only** (keep the ACL): set `association_resource_arns = []` in `waf.tf` (or
   `var.waf.enabled = false`) and `terraform apply`. The ALB keeps serving; WAF stops
   inspecting.
2. **Full removal (targeted):**
   ```
   AWS_PROFILE=camion-dev terraform -chdir=environments/dev/eu-north-1 destroy \
     -target=module.waf \
     -target=aws_cloudwatch_log_group.waf \
     -target=aws_cloudwatch_metric_alarm.waf_rate_limit_counted
   ```
   then delete `waf.tf` and the `waf` variable, and `terraform plan` to confirm clean.
3. **Code revert:** `git revert`/remove `waf.tf` + the `variable "waf"` block, then
   `terraform apply` (destroys the 5 resources).

## Notes
- WAF disassociation does not interrupt ALB listeners or target groups.
- The web ACL must be disassociated before it can be deleted — option 2's targeted destroy
  handles ordering automatically.

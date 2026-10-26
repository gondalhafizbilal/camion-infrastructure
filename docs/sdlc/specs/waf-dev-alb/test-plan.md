# Test plan — WAFv2 (count mode) on the dev ALB

## Static validation (done pre-apply)
- `terraform fmt` clean on `waf.tf` / `variables.tf`.
- `terraform validate` passes.
- `terraform plan` shows **5 to add, 0 change, 0 destroy** and, in the planned
  `aws_wafv2_web_acl`:
  - `default_action { allow {} }`
  - every managed rule `override_action { count {} }`
  - rate rule `action { count {} }` (limit 2000, evaluation_window_sec 300, key IP)
  - **no** `AWSManagedRulesBotControlRuleSet` rule (toggle off)
- `var.waf` `validation` rejects any non-`"count"` override/action (negative test: temporarily
  set one to `"block"` ⇒ `terraform validate` fails with the count-mode error message).

## Post-apply (after approval)
1. `aws wafv2 get-web-acl --scope REGIONAL --name camion-dev-alb --region eu-north-1 ...`
   shows `DefaultAction: Allow` and each rule `OverrideAction: Count` / rate `Action: Count`.
2. `aws wafv2 list-resources-for-web-acl` lists the ALB ARN (association live).
3. Drive traffic above 2000 req/5min from one IP → CloudWatch `AWS/WAFV2 CountedRequests`
   for `Rule=rate-limit-ip` increments, **requests still 200/served** (count, not block).
4. CloudWatch log group `aws-waf-logs-camion-dev-alb` receives WAF log records.
5. Alarm `camion-dev-alb-waf-rate-limit-counted` transitions to ALARM under sustained load
   and notifies the shared SNS topic.

## Acceptance gate
No 403s attributable to WAF; counted metrics visible; ALB serves identically to pre-WAF.

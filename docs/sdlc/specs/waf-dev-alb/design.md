# Design — WAFv2 (count mode) on the dev ALB

Built with **`cloudposse/waf/aws` v1.17.0**, scope `REGIONAL`, associated to
`module.backend_load_balancer.lb_arn`. Config driven by `var.waf` (in `variables.tf`) so
dev/prod differ only via tfvars. Implemented in `environments/dev/eu-north-1/waf.tf`.

## Rule set (all COUNT, default_action = allow)

| # | Ask | rule name | prio | type | group / params | action |
|---|-----|-----------|------|------|----------------|--------|
| 1 | DDoS | `ip-reputation` | 10 | managed | `AWSManagedRulesAmazonIpReputationList` | `override_action=count` |
| 2 | DDoS | `anonymous-ip` | 20 | managed | `AWSManagedRulesAnonymousIpList` | `override_action=count` |
| 3 | Scraping | `common-rule-set` | 30 | managed | `AWSManagedRulesCommonRuleSet` | `override_action=count` |
| 4 | Bot (**off** by default) | `bot-control` | 40 | managed | `AWSManagedRulesBotControlRuleSet` (COMMON) | `override_action=count` |
| 5 | Rate limit | `rate-limit-ip` | 100 | rate | `limit=2000 / 300s / aggregate_key=IP` | `action=count` |

WCU ≈ 825 (bot off) — under the 1500 default.

## Key decisions
- **Count-mode contract.** The Cloud Posse module emits `override_action { count {} }` only
  when the value is exactly `"count"` (any other value ⇒ `none {}` = **enforce**), and
  `action { count {} }` for the rate rule only when `"count"`. The literal `"count"` is
  load-bearing, so `var.waf` carries a `validation` block asserting it on every rule.
- **Bot Control gated** behind `var.waf.bot_control_enabled` (default `false`) and filtered
  out of the rule list by a `local`, so the paid AMR is not deployed in dev. Its
  `inspection_level` is nested into `statement.managed_rule_group_configs.aws_managed_rules_bot_control_rule_set`
  (where the module reads it).
- **Rate key = `IP`** (not `FORWARDED_IP`): the ALB is the direct internet origin, so XFF is
  client-spoofable here.
- **Logging** to a CloudWatch log group `aws-waf-logs-camion-dev-alb` (name must start with
  `aws-waf-logs-`), 30-day retention, **AWS-managed encryption** — the shared KMS module
  exposes no CloudWatch-Logs CMK and one would need a `logs.<region>.amazonaws.com` key
  policy; deferred (WAF telemetry is non-secret).
- **Alarm** `camion-dev-alb-waf-rate-limit-counted` on `AWS/WAFV2 CountedRequests`
  (Sum > 1000 / 5min) to the shared SNS topic — early signal that we'd be throttling if
  enforcing. The `WebACL` dimension is the ACL **name** (`camion-dev-alb`), not the resource
  id.

## Files
- CREATE: `environments/dev/eu-north-1/waf.tf`
- MODIFY: `environments/dev/eu-north-1/variables.tf` (`variable "waf"` with committed default
  rule set — WAF config is non-secret, so it lives in code for reproducibility; tfvars
  override only for prod/tuning).

## Verified against ground truth
- `module.backend_load_balancer.lb_arn` (`modules/load-balancer/output.tf:6`),
  `module.alarms_sns_topic.sns_topic.arn` (`ecs-alarms.tf:10`).
- Module input schema confirmed against `cloudposse/terraform-aws-waf` tag `v1.17.0` source.
- Module needs TF `>=1.3.0` / AWS `>=6.2.0`; repo is `>=1.5.3` / `>=6.13.0` — compatible.

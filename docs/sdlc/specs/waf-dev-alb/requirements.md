# Requirements — WAFv2 (count mode) on the dev ALB

## Goal
Add edge protection to the dev shared public ALB (`module.backend_load_balancer`) covering
three asks, all deployed **non-blocking (Count mode)** for a safe dev rollout:

1. **DDoS protection (L7).** AWS Shield Standard already covers L3/L4 automatically and free.
   Add WAF L7 coverage via AWS managed IP-reputation and anonymous-IP rule groups.
2. **Scraping protection.** AWS managed Common Rule Set now; optional paid Bot Control behind
   a toggle (default off in dev for cost).
3. **Request throttling / rate limiting.** Per-IP WAFv2 rate-based rule.

## Constraints
- **Count mode only** in dev: nothing is blocked. `default_action = allow`; managed groups
  `override_action = count`; rate rule `action = count`.
- Use the **`cloudposse/waf/aws`** registry module (repo prefers Cloud Posse modules), not
  hand-rolled `aws_wafv2_*`.
- Region `eu-north-1`, scope `REGIONAL` (ALB). Tag with `var.common_tags`.
- dev/prod identical file names; differences via tfvars. **dev only now**; prod deferred.
- No new public exposure, no over-broad IAM, no committed secrets.
- Cost-aware: paid Bot Control AMR off by default.

## Out of scope
- Enforce (block) mode, prod mirror, CloudFront-scope WAF, Shield Advanced, a dedicated
  CloudWatch-Logs CMK.

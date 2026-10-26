# Acceptance criteria — WAFv2 (count mode) on the dev ALB

- [x] WAFv2 web ACL (scope REGIONAL, `eu-north-1`) associated with the dev ALB via the
      **`cloudposse/waf/aws` v1.17.0** module.
- [x] Covers all three asks: DDoS (IP-reputation + anonymous-IP), scraping (Common Rule Set),
      rate limiting (per-IP rate-based rule).
- [x] **Count mode:** `default_action = allow`; all managed groups `override_action = count`;
      rate rule `action = count`. Verified in `terraform plan`.
- [x] Paid Bot Control AMR gated behind `var.waf.bot_control_enabled` (default off) → not in
      the dev plan.
- [x] WAF logging to `aws-waf-logs-camion-dev-alb` (30-day retention, encrypted at rest,
      tagged).
- [x] Rate-limit count alarm wired to the shared SNS topic.
- [x] `terraform fmt` clean · `validate` passes · `plan` = 5 add / 0 change / 0 destroy,
      reviewed.
- [x] No new public exposure, no IAM changes, no secrets committed; change scoped to
      `waf.tf` + `variables.tf`.
- [x] Rollback documented (zero blast).
- [ ] **`terraform apply` pending explicit approval.**
- [ ] Prod mirror (deferred).

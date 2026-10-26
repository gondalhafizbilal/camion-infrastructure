# Plan — WAFv2 (count mode) on the dev ALB

Small, resumable tasks. Status as of implementation.

- [x] Add `variable "waf"` to `environments/dev/eu-north-1/variables.tf` (count-mode default
      rule set + `bot_control_enabled` toggle + `validation` guardrail).
- [x] Create `environments/dev/eu-north-1/waf.tf` (cloudposse/waf/aws module call, log group,
      bot-filter `local`, optional rate-limit alarm, `waf_web_acl_arn` output).
- [x] `terraform fmt` (scoped to the two new/edited files; reverted incidental fmt churn on
      unrelated pre-existing files).
- [x] `terraform init` (downloads `cloudposse/waf/aws 1.17.0`; lock file updated).
- [x] `terraform validate` — passes (pre-existing s3-module deprecation warnings only).
- [x] `terraform plan` — **5 to add, 0 to change, 0 to destroy**; count-mode confirmed.
- [x] Spec docs + MEMORY/PROJECT-PLAN updated.
- [ ] **`terraform apply` — NOT done; awaits explicit approval** (CLAUDE.md golden rule).

## Deferred / follow-ups
- Prod mirror: add an identical `waf.tf` to `environments/prod/eu-north-1/` after dev soak.
- After observing counted metrics, flip selected rules `count → enforce` via tfvars.
- Optionally add a CloudWatch-Logs CMK to the shared KMS module for log encryption.

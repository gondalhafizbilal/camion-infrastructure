# Project Plan — Camion Infrastructure

> Prioritised backlog + operating model. Produced during PROJECT INIT (2026-06-03).
> This is a proposal for review — **no work is started until approved.**

## Operating model

Roles are applied as **labeled passes** over each change (not separate agents), orchestrated
in one workflow: Product Analyst → Solution Architect → Backend/Frontend/Infrastructure →
Security Reviewer → QA → Documentation → Code Reviewer.

Principles: security by default, least privilege, automated tests/validation, CI/CD,
observability, cost-awareness, rollback-by-design, and **prefer boring proven solutions**.

### Memory protocol
- **Start of every task:** read `MEMORY.md`, `ARCHITECTURE.md`, `PATTERNS.md`,
  `PROJECT-PLAN.md`, and `specs/*` if present; treat them as ground truth.
- **End of every task:** update `MEMORY.md` (summarized, deduplicated) and any affected docs.

### Per-feature workflow
1. Search `docs/sdlc/` for prior work and reuse it.
2. Create `docs/sdlc/specs/<feature>/` with `requirements.md`, `design.md`, `plan.md`
   (small resumable tasks), `test-plan.md`, `rollback.md`, `acceptance-criteria.md`.
3. Validate assumptions; ask focused questions only when confidence is low.
4. On approval: implement → write tests/validation → run validation → update docs → update
   memory → deliver a task-completion report (changes, tests, docs, memory, risks).

### Definition of done for an infra change
`terraform fmt` clean · `terraform validate` passes · `plan` reviewed and attached ·
security pass (no new public exposure / over-broad IAM / unencrypted resource) ·
rollback documented · `MEMORY.md` + affected docs updated · no secrets committed.

## Prioritised backlog

Priority: **P0** = correctness/security/safety now · **P1** = important soon ·
**P2** = improvement · **P3** = nice-to-have. None of these are started.

### P0 — Safety & hygiene
1. **Stop tracking committed plan files.** `*.tfplan` / `*.plan` exist in `environments/*`
   (e.g. `prod-changes.tfplan`, `tfplan`, `pi.plan`). They are now in `.gitignore` but the
   tracked copies should be `git rm --cached`. Plans can embed resource values.
2. **Confirm no secrets are committed.** Audit history/working tree for `terraform.tfvars`,
   `*.env`, comparison reports (gitignore covers them going forward). Rotate anything that
   leaked.
3. **Document the manual apply runbook** (profiles, order, DNS validation two-step) so
   applies are reproducible and reviewable.

### P1 — Automation & guardrails
4. **CI for Terraform**: GitHub Actions (or chosen CI) running `fmt -check`, `validate`,
   and `plan` on PR per environment, with the plan posted for review. Read-only AWS role
   via OIDC for plan.
5. **Policy/lint gates**: add `tflint`, and a security scanner (`checkov` or `tfsec`/Trivy)
   to CI; fail on high findings. `terraform-docs` for module READMEs.
6. **Pin module versions consistently.** Several registry modules are referenced without an
   explicit `version =`; pin all to avoid surprise upgrades.
7. **Pre-commit hooks**: `terraform fmt`, `tflint`, secret scanning (gitleaks) to catch
   issues before commit.

### P2 — Resilience & observability
8. **Prod data-tier HA review.** Confirm prod Aurora has a replica and ElastiCache has
   `automatic_failover_enabled = true` (dev intentionally single-node). Document RTO/RPO.
9. **Backups & retention policy** for Aurora (snapshot retention currently low/`skip_final
   _snapshot = true` in dev) and state-bucket lifecycle. Define per-env.
   **[PARTIAL — prod]** On-demand logical-dump Lambda `prod-db-backup` → S3
   (`prod-db-backups-377404936654-eu-north-1`) added out-of-band (CLI+Docker, **not in TF
   state**); spec `specs/db-backup-lambda/`. Remaining: import to Terraform (replicate to
   dev under identical file name), add an S3 lifecycle rule (Glacier/expire), decide on an
   EventBridge schedule, and reconcile with native Aurora snapshot retention/RPO.
10. **Alarm coverage review**: ensure every service + data store has CPU/mem/health alarms
    and that SNS subscriptions reach a real on-call path; verify Chatbot/Slack delivery.
11. **Centralised logging/retention**: confirm log group retention is set (cost + audit).

### P2 — Security hardening
12. **IAM least-privilege audit.** Some statements use `Resource = "*"` (e.g. ECS Exec SSM
    session actions, `ecs:UpdateService`). Scope where feasible.
13. **ALB/WAF**: evaluate AWS WAF on the public ALB and CloudFront for the e-commerce
    surface (rate limiting, common rules). **[APPLIED — dev + prod]** WAFv2 on the ALB
    (count mode) via `cloudposse/waf/aws` in `waf.tf` + `var.waf` (DDoS, scraping,
    rate limit); spec `specs/waf-dev-alb/`. Applied dev 2026-06-08 (`camion-dev-alb`) and
    prod 2026-06-09 (`camion-prod-alb`), both via targeted apply (5 add / 0 change /
    0 destroy each). `var.waf` carries all count-mode config in its defaults (`default = {}`),
    so dev/prod `waf.tf` + `var.waf` are identical and env differences come from
    `var.aws_profile`/ALB/SNS only. Remaining: soak on counted metrics in both envs, then
    selective enforce (flip chosen rules count→block); CloudFront-scope WAF still open.
14. **S3 public-access & TLS-only**: verify all buckets have `BlockPublicAccess` and
    enforce `aws:SecureTransport`; the commented-out state-bucket policy denying non-KMS
    PUTs in the bootstrap template could be re-enabled.
    **Assets-CDN public-access-block conflict.** Two `aws_s3_bucket_public_access_block`
    resources manage the *same* assets bucket per env: `module.assets_bucket…s3bucket_nopublic[0]`
    (all-true) vs `module.assets_cdn…origin[0]` (`cloudposse/cloudfront-s3-cdn ~> 2.0`, whose
    `block_origin_public_access_enabled` defaulted to `false`, so it wanted
    `block_public_policy`/`restrict_public_buckets`=false). They ping-ponged every apply.
    **Root cause / fix (2026-06-08):** in the module, `block_public_policy` +
    `restrict_public_buckets` are wired to `var.block_origin_public_access_enabled`
    (the other two booleans are hardcoded true); the OAC bucket policy is a conditional
    service-principal grant that does NOT depend on this var, so setting it true has no
    side effect beyond the two booleans. Fix = `block_origin_public_access_enabled = true`
    added to the `assets_cdn` block in dev + prod `static-assets.tf`.
    - **[DONE — dev]** Dev live bucket was already all-true; the edit makes TF agree →
      dev now plans **clean (No changes)**, no apply needed. The earlier WAF dev apply was
      `-target`ed to dodge this; that workaround is no longer required.
    - **[DONE — prod]** Prod live bucket `prod-assets-377404936654-eu-north-1` had been
      **loosened** (`BlockPublicPolicy=false`/`RestrictPublicBuckets=false`) — a real
      pre-existing gap. Applied 2026-06-09 via targeted apply (the 2 PAB resources only):
      `0 add / 2 change / 0 destroy`, both flipped false→true → bucket now fully private.
      Verified live (all-true), re-plan = **No changes**, and the OAC bucket policy
      (CloudFront service principal + `SourceArn` condition, plus SSL-only deny) is intact,
      so delivery is unaffected. Ping-pong resolved permanently in both envs.

### P3 — Developer experience & cost
15. **Migrate DNS to Route 53** (or document why staying on Hostinger) to remove the manual
    ACM validation step.
16. **Cost dashboard / budgets + alerts** per account; tag-based cost allocation already in
    place via `common_tags`.
17. **`terraform-docs`-generated module docs** and a top-level repo README.

## Suggested first iteration (on approval)
P0 items 1–3 (no infra mutation — just hygiene + a runbook), then P1 item 4 (plan-only CI).
These are low-risk, high-leverage, and unblock safe review of everything else.

# Acceptance criteria — Prod DB-dump Lambda

| # | Criterion | Status |
|---|---|---|
| 1 | Lambda exists in prod (`377404936654`/`eu-north-1`), State=Active | ✅ |
| 2 | Invoking it writes a dump to `s3://prod-db-backups-377404936654-eu-north-1/app/` | ✅ (two objects, ~70 MiB) |
| 3 | Object key contains date+time (`app-<YYYYMMDDTHHMMSSZ>.dump`) | ✅ `app-20260608T132113Z.dump` |
| 4 | Password sourced from Secrets Manager at runtime; no plaintext secret in env/files | ✅ env holds only the secret ARN |
| 5 | Connects as `masteruser` to DB `app` | ✅ |
| 6 | Clean invocation: StatusCode 200, no FunctionError, returns bucket/key/size | ✅ |
| 7 | Dump is a valid restorable archive | ✅ `pg_restore --list`: 595 TOC entries, 104 tables / 150 sequences, from server 17.7 |
| 8 | Backup bucket is private + encrypted (SSE-KMS) + versioned | ✅ |
| 9 | Least-privilege role (write-only to bucket) | ✅ |
| 10 | Log group retention set | ✅ 30 days |
| 11 | Built without Terraform | ✅ AWS CLI + Docker |

## Verification commands
See `runbook.md` (invoke, list, validate). Last verified: 2026-06-08.

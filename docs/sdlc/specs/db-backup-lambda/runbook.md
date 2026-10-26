# Runbook — Prod DB-dump Lambda

All commands: `export AWS_PROFILE=camion-prod AWS_REGION=eu-north-1` (account 377404936654).

## Take a backup (on-demand)
```bash
aws lambda invoke --function-name prod-db-backup \
  --cli-binary-format raw-in-base64-out --payload '{}' \
  --cli-read-timeout 900 /tmp/out.json
cat /tmp/out.json   # {"bucket":..., "key":"app/app-<ts>.dump", "size_bytes":...}
```
List backups:
```bash
aws s3 ls s3://prod-db-backups-377404936654-eu-north-1/app/ --human-readable
```

## Update the function code
Source lives in `docs/sdlc/specs/db-backup-lambda/` (`Dockerfile`, `handler.py`).
```bash
cd docs/sdlc/specs/db-backup-lambda
N=3   # next image tag
aws ecr get-login-password | docker login --username AWS --password-stdin \
  377404936654.dkr.ecr.eu-north-1.amazonaws.com
docker build --platform linux/amd64 -t 377404936654.dkr.ecr.eu-north-1.amazonaws.com/prod-db-backup:$N .
docker push 377404936654.dkr.ecr.eu-north-1.amazonaws.com/prod-db-backup:$N
aws lambda update-function-code --function-name prod-db-backup \
  --image-uri 377404936654.dkr.ecr.eu-north-1.amazonaws.com/prod-db-backup:$N
aws lambda wait function-updated --function-name prod-db-backup
```
> Build on `--platform linux/amd64` (Lambda is x86_64). On Apple Silicon this cross-builds.

## Validate a dump
```bash
aws s3 cp s3://prod-db-backups-377404936654-eu-north-1/app/<file>.dump /tmp/app.dump
docker run --rm --platform linux/amd64 \
  --entrypoint /usr/lib/postgresql/17/bin/pg_restore \
  -v /tmp/app.dump:/app.dump:ro 377404936654.dkr.ecr.eu-north-1.amazonaws.com/prod-db-backup:2 \
  --list /app.dump | head        # prints TOC; non-empty = valid archive
```

## Restore (to a scratch DB — never restore over prod blindly)
```bash
PGPASSWORD=<pw> pg_restore -h <target-host> -p <port> -U masteruser -d <target-db> \
  --no-owner --clean --if-exists /tmp/app.dump
```

## Logs
```bash
aws logs tail /aws/lambda/prod-db-backup --since 1h --follow
```

## Notes / gotchas
- **DB port is 3306**, not the Postgres default 5432 (set in the function's `DB_PORT` env).
- Env holds only the secret **ARN**; the password is fetched at runtime — never put the
  password in env or in any committed file.

"""On-demand logical backup of the prod Aurora PostgreSQL `app` database.

Fetches the master password from Secrets Manager at runtime (never stored in env),
runs `pg_dump -Fc` and streams its stdout straight into an S3 multipart upload with a
UTC-timestamped object key. No /tmp size limit because nothing is buffered to disk.
"""
import os
import json
import datetime
import subprocess

import boto3


def handler(event, context):
    sm = boto3.client("secretsmanager")
    secret = json.loads(
        sm.get_secret_value(SecretId=os.environ["SECRET_ARN"])["SecretString"]
    )

    ts = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    key = f'{os.environ["S3_PREFIX"]}/app-{ts}.dump'

    env = {**os.environ, "PGPASSWORD": secret["password"]}
    cmd = [
        "pg_dump",
        "-h", os.environ["DB_HOST"],
        "-p", os.environ.get("DB_PORT", "5432"),
        "-U", os.environ["DB_USER"],
        "-d", os.environ["DB_NAME"],
        "-Fc",          # custom (compressed) format -> restore with pg_restore
        "--no-owner",
    ]

    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)

    # Count bytes as they stream so we can report size without needing s3:GetObject
    # (the role is intentionally write-only).
    class _Counting:
        def __init__(self, src):
            self.src = src
            self.n = 0

        def read(self, size=-1):
            chunk = self.src.read(size)
            self.n += len(chunk)
            return chunk

    counter = _Counting(proc.stdout)
    s3 = boto3.client("s3")
    # Streaming multipart upload straight from pg_dump's stdout pipe.
    s3.upload_fileobj(counter, os.environ["S3_BUCKET"], key)

    err = proc.stderr.read().decode()
    rc = proc.wait()
    if rc != 0:
        raise RuntimeError(f"pg_dump exited {rc}: {err}")

    return {
        "bucket": os.environ["S3_BUCKET"],
        "key": key,
        "size_bytes": counter.n,
    }

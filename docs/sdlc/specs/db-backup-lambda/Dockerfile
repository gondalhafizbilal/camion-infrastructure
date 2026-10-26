# Prod DB-dump Lambda image.
# Base = official PostgreSQL 17 so pg_dump matches Aurora server 17.7 (pg_dump major >= server major).
# Adds the AWS Lambda Runtime Interface Client + boto3 so the image runs as a Lambda function.
FROM postgres:17-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-pip ca-certificates && rm -rf /var/lib/apt/lists/*
RUN pip3 install --break-system-packages awslambdaric boto3

WORKDIR /var/task
COPY handler.py .

# pg_dump resolves on PATH (/usr/lib/postgresql/17/bin) provided by the postgres base image.
ENTRYPOINT ["python3", "-m", "awslambdaric"]
CMD ["handler.handler"]

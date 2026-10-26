# Bake k6 + scripts + fixtures + entrypoint. Single image, parameterized at run-time.
FROM grafana/k6:0.51.0

USER root

# awscli for uploading results to S3 from inside the task.
RUN apk add --no-cache aws-cli bash

WORKDIR /app

COPY scripts/ /app/scripts/
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# k6 image runs as `k6` by default; ensure it can read everything.
RUN chown -R k6:k6 /app

USER k6

ENTRYPOINT ["/app/entrypoint.sh"]

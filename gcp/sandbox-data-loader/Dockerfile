# =============================================================================
# GCP Sandbox Database Loader — Dockerfile
# =============================================================================
# Base image: google/cloud-sdk:alpine gives us:
#   - gcloud CLI (for GCS operations via gcloud storage + Cloud SQL Admin API)
#   - Alpine Linux (small footprint)
#
# We install:
#   - postgresql17-client : pg_dump, pg_restore, psql
#   - bash               : orchestration scripting
#   - jq                 : JSON parsing
#   - Cloud SQL Proxy v2 : secure IAM-authenticated tunnel to Cloud SQL
# =============================================================================

FROM google/cloud-sdk:alpine

# ---------------------------------------------------------------------------
# Build arguments (override at build time if needed)
# ---------------------------------------------------------------------------
ARG CLOUD_SQL_PROXY_VERSION=2.13.0

# ---------------------------------------------------------------------------
# Install system packages
# ---------------------------------------------------------------------------
RUN apk add --no-cache \
      bash \
      postgresql17-client \
      jq \
      curl \
      ca-certificates \
    && rm -rf /var/cache/apk/*

# ---------------------------------------------------------------------------
# Install Cloud SQL Proxy v2
#   - Uses ADC automatically (no credential file required)
#   - --auto-iam-authn enables IAM database authentication
# ---------------------------------------------------------------------------
RUN curl -fsSL \
      "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v${CLOUD_SQL_PROXY_VERSION}/cloud-sql-proxy.linux.amd64" \
      -o /usr/local/bin/cloud-sql-proxy \
    && chmod +x /usr/local/bin/cloud-sql-proxy

# ---------------------------------------------------------------------------
# Copy orchestration scripts
# ---------------------------------------------------------------------------
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh /scripts/lib/*.sh

# ---------------------------------------------------------------------------
# Non-root user for least-privilege execution
# ---------------------------------------------------------------------------
RUN addgroup -S loader && adduser -S loader -G loader
USER loader

# ---------------------------------------------------------------------------
# Working directory for temp files (dumps, scripts, logs)
# ---------------------------------------------------------------------------
WORKDIR /tmp/loader

ENTRYPOINT ["/scripts/entrypoint.sh"]

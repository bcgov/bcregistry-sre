#!/bin/bash
set -eo pipefail

# 1. Determine active Docker socket from context
echo "Detecting Docker context endpoint..."
DOCKER_ENDPOINT=$(docker context inspect "$(docker context show)" --format '{{.Endpoints.docker.Host}}' 2>/dev/null || echo "")

if [ -n "$DOCKER_ENDPOINT" ]; then
    export DOCKER_HOST="$DOCKER_ENDPOINT"
    echo "Using DOCKER_HOST=${DOCKER_HOST}"
else
    echo "Using default Docker host"
fi

# 2. Run pytest
echo "Running pytest test_app.py..."
uv run pytest test_app.py

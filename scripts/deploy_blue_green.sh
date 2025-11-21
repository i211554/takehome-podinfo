#!/usr/bin/env bash
# Usage: deploy_blue_green.sh <color> <image_tag(optional)>
# color = blue|green
set -euo pipefail

COLOR=${1:-blue}
IMAGE_TAG=${2:-latest}
COMPOSE_DIR="$(cd "$(dirname "$0")/.." && pwd)/docker"
UPSTREAM_FILE="$COMPOSE_DIR/upstream.conf"
NGINX_CONTAINER_NAME="nginx"
STATE_FILE="$COMPOSE_DIR/.current_color"

echo "Starting deploy for color=${COLOR}, image_tag=${IMAGE_TAG}"

cd "$COMPOSE_DIR"

# 1) Optionally update override to use requested image tag (if CI provides image)
# This is optional: if you want to deploy a particular image tag, you'd rewrite
# docker-compose.<color>.yml before starting. For now we assume image in compose is set.

# 2) Start containers for this color
echo "Starting services for ${COLOR}..."
docker-compose -f docker-compose.yml -f docker-compose.${COLOR}.yml up -d --remove-orphans

# 3) Wait for backend to pass healthcheck
BACKEND_URL="http://backend_${COLOR}:9898/metrics"
echo "Waiting for backend metrics at ${BACKEND_URL} ..."
# run healthcheck inside docker network via docker run --rm --network
# Use a small temporary container to curl internal hostname from same network
attempts=0
max_attempts=12
sleep_time=5
while [ $attempts -lt $max_attempts ]; do
  if docker run --rm --network "$(docker network ls --filter name=app-net -q)" appropriate/curl:latest -sSf "$BACKEND_URL" >/dev/null 2>&1; then
    echo "Backend ${COLOR} healthy."
    break
  fi
  attempts=$((attempts+1))
  echo "Waiting for backend... (${attempts}/${max_attempts})"
  sleep $sleep_time
done

if [ $attempts -ge $max_attempts ]; then
  echo "ERROR: backend ${COLOR} failed health checks."
  echo "Taking down new color"
  docker-compose -f docker-compose.yml -f docker-compose.${COLOR}.yml down
  exit 1
fi

# 4) Generate new upstream.conf pointing at the selected color for both frontend & backend
cat > "$UPSTREAM_FILE" <<EOF
upstream frontend_upstream {
    server frontend_${COLOR}:9898;
}

upstream backend_upstream {
    server backend_${COLOR}:9898;
}
EOF

# 5) Reload nginx
echo "Reloading nginx..."
docker exec "$NGINX_CONTAINER_NAME" nginx -s reload || {
  echo "Nginx reload failed, reverting."
  # revert upstream
  if [ -f "$STATE_FILE" ]; then
    PREV=$(cat "$STATE_FILE")
    echo "Reverting to $PREV"
    cat > "$UPSTREAM_FILE" <<EOF
upstream frontend_upstream {
    server frontend_${PREV}:9898;
}

upstream backend_upstream {
    server backend_${PREV}:9898;
}
EOF
    docker exec "$NGINX_CONTAINER_NAME" nginx -s reload || echo "Manual intervention required"
  fi
  exit 1
}

# 6) Mark current color
echo "$COLOR" > "$STATE_FILE"

# 7) Tear down the other color to free resources
OTHER="blue"
if [ "$COLOR" = "blue" ]; then OTHER="green"; fi

echo "Stopping other color: $OTHER"
docker-compose -f docker-compose.yml -f docker-compose.${OTHER}.yml down

echo "Deploy to ${COLOR} complete."

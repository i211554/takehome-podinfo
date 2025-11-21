#!/usr/bin/env bash
# roll back to previous color saved in .previous_color (or flip)
set -euo pipefail
COMPOSE_DIR="$(cd "$(dirname "$0")/.." && pwd)/docker"
STATE_FILE="$COMPOSE_DIR/.current_color"
UPSTREAM_FILE="$COMPOSE_DIR/upstream.conf"
NGINX_CONTAINER_NAME="nginx"

if [ ! -f "$STATE_FILE" ]; then
  echo "No state file found. Nothing to rollback."
  exit 1
fi

CURRENT=$(cat "$STATE_FILE")
if [ "$CURRENT" = "blue" ]; then
  TARGET="green"
else
  TARGET="blue"
fi

echo "Rolling back to ${TARGET} (current is ${CURRENT})"

# Start target color if not running
docker-compose -f docker-compose.yml -f docker-compose.${TARGET}.yml up -d

# Update upstream
cat > "$UPSTREAM_FILE" <<EOF
upstream frontend_upstream {
    server frontend_${TARGET}:9898;
}

upstream backend_upstream {
    server backend_${TARGET}:9898;
}
EOF

docker exec "$NGINX_CONTAINER_NAME" nginx -s reload

echo "$TARGET" > "$STATE_FILE"
echo "Rollback to ${TARGET} completed."

#!/usr/bin/env bash
# healthcheck.sh <url> <retries> <initial_delay_seconds>
set -eo pipefail

URL=${1:-http://localhost/}
RETRIES=${2:-5}
DELAY=${3:-2}

count=0
delay=$DELAY

while [ $count -lt $RETRIES ]; do
  if curl -sSf "$URL" >/dev/null; then
    echo "OK: $URL"
    exit 0
  else
    echo "Attempt $((count+1))/$RETRIES failed for $URL. Retrying in ${delay}s..."
    sleep $delay
    delay=$((delay * 2))
    count=$((count+1))
  fi
done

echo "ERROR: healthcheck failed for $URL after $RETRIES attempts."
exit 1

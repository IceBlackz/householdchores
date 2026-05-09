#!/bin/sh
set -eu

if [ -n "${ADMIN_EMAIL:-}" ] && [ -n "${ADMIN_PASSWORD:-}" ]; then
  /pb/pocketbase superuser upsert "$ADMIN_EMAIL" "$ADMIN_PASSWORD"
fi

exec /pb/pocketbase serve --http=0.0.0.0:9010

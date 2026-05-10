#!/bin/sh
set -eu

shutdown() {
  if [ -n "${PB_PID:-}" ]; then
    kill "$PB_PID" 2>/dev/null || true
  fi
  if [ -n "${NGINX_PID:-}" ]; then
    kill "$NGINX_PID" 2>/dev/null || true
  fi
}

trap shutdown INT TERM

if [ -n "${ADMIN_EMAIL:-}" ] && [ -n "${ADMIN_PASSWORD:-}" ]; then
  /pb/pocketbase superuser upsert "$ADMIN_EMAIL" "$ADMIN_PASSWORD"
fi

/pb/pocketbase serve --http=0.0.0.0:9010 &
PB_PID="$!"

nginx -g "daemon off;" &
NGINX_PID="$!"

while kill -0 "$PB_PID" 2>/dev/null && kill -0 "$NGINX_PID" 2>/dev/null; do
  sleep 2
done

shutdown
wait "$PB_PID" 2>/dev/null || true
wait "$NGINX_PID" 2>/dev/null || true
exit 1

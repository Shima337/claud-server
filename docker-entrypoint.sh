#!/bin/sh
set -e
# Railway may set PORT in various formats; normalize to a plain number for openclaw
PORT="${PORT:-8080}"
PORT=$(echo "$PORT" | tr -cd '0-9')
[ -z "$PORT" ] && PORT=8080
exec npx openclaw gateway --port "$PORT" --bind lan --allow-unconfigured

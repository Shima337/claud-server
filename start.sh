#!/usr/bin/env sh
# Start OpenClaw gateway for this (second) instance.
# Uses PORT from env (Railway sets it); defaults to 8080.
# Set OPENCLAW_STATE_DIR for persistence (e.g. /data/.openclaw on Railway).

set -e
export PORT="${PORT:-8080}"
exec openclaw gateway --port "$PORT" --bind lan --allow-unconfigured

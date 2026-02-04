#!/bin/sh
set -e
# Railway may set PORT in various formats; normalize to a plain number for openclaw
PORT="${PORT:-8080}"
PORT=$(echo "$PORT" | tr -cd '0-9')
[ -z "$PORT" ] && PORT=8080

# Trust proxy headers (e.g. Railway) so token auth works and "pairing required" is not forced
CONFIG="${OPENCLAW_STATE_DIR:-/data/.openclaw}/openclaw.json"
if [ -f "$CONFIG" ]; then
  OPENCLAW_CONFIG_PATH="$CONFIG" node -e "
    const fs=require('fs');
    const p=process.env.OPENCLAW_CONFIG_PATH||'/data/.openclaw/openclaw.json';
    try {
      const cfg=JSON.parse(fs.readFileSync(p,'utf8'));
      cfg.gateway=cfg.gateway||{};
      if(!cfg.gateway.trustedProxies||cfg.gateway.trustedProxies.length===0){
        cfg.gateway.trustedProxies=['0.0.0.0/0'];
        fs.writeFileSync(p,JSON.stringify(cfg,null,2));
      }
    } catch(_) {}
  " 2>/dev/null || true
fi

exec npx openclaw gateway --port "$PORT" --bind lan --allow-unconfigured

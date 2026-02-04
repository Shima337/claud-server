# Second OpenClaw instance — gateway + Telegram only (Railway / any Docker)
# Node 22+, state in OPENCLAW_STATE_DIR (mount volume at /data on Railway)

FROM node:22-bookworm-slim

WORKDIR /app

# Some transitive deps may require `git` during install (npm will spawn git).
RUN apt-get update \
  && apt-get install -y --no-install-recommends git ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Copy dependency list and install (no global openclaw — use local for reproducible version)
COPY package.json ./
RUN npm install --omit=dev

COPY . .

# Runtime: set state dir so volume mount at /data persists config/workspace
ENV NODE_ENV=production
ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/workspace

# Ensure state dir exists when volume is mounted at /data (avoids startup errors)
RUN mkdir -p /data/.openclaw /data/workspace

# Railway sets PORT; gateway must listen on 0.0.0.0 (--bind lan)
# Allow start without pre-existing config (wizard at /setup)
CMD ["sh", "-c", "npx openclaw gateway --port ${PORT:-8080} --bind lan --allow-unconfigured"]

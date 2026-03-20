#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo "  Full-Stack Dev Box starting..."
echo "========================================"

# ── Git identity ─────────────────────────────────────────────
[ -n "${GIT_NAME:-}" ]  && git config --global user.name  "${GIT_NAME}"
[ -n "${GIT_EMAIL:-}" ] && git config --global user.email "${GIT_EMAIL}"
git config --global init.defaultBranch main
git config --global pull.rebase false

# ── SSH permissions ──────────────────────────────────────────
if [ -d "/home/coder/.ssh" ]; then
    chmod 700 /home/coder/.ssh 2>/dev/null || true
    chmod 600 /home/coder/.ssh/* 2>/dev/null || true
fi

# ── Claude Code config (initialize volume on first run) ──────
sudo chown -R coder:coder /home/coder/.claude 2>/dev/null || true
mkdir -p /home/coder/.claude
if [ ! -f "/home/coder/.claude/settings.json" ]; then
    cp /home/coder/.claude-defaults/settings.json  /home/coder/.claude/settings.json
    cp /home/coder/.claude-defaults/mcp_settings.json /home/coder/.claude/mcp_settings.json
    echo "Initialized Claude Code config from defaults"
fi

# ── Inject GitHub token into MCP config ──────────────────────
if [ -n "${GITHUB_TOKEN:-}" ]; then
    sed -i "s|\${GITHUB_TOKEN}|${GITHUB_TOKEN}|g" /home/coder/.claude/mcp_settings.json
fi

# ── Write Claude Code .env ────────────────────────────────────
# ANTHROPIC_API_KEY: set for API key auth; leave empty to use `claude login` (subscription)
# ANTHROPIC_BASE_URL: leave empty for real api.anthropic.com
cat > /home/coder/.claude/.env << EOF
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-}
ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL:-}
API_TIMEOUT_MS=${API_TIMEOUT_MS:-300000}
EOF

# ── Docker daemon (DinD) ──────────────────────────────────────
echo "Starting Docker daemon..."
sudo dockerd --host=unix:///var/run/docker.sock > /tmp/dockerd.log 2>&1 &
until sudo docker info > /dev/null 2>&1; do
    sleep 1
done
echo "Docker daemon ready"

# ── Welcome banner ────────────────────────────────────────────
cat >> /home/coder/.bashrc << 'BANNER'

echo ""
echo -e "\033[1;36m  Full-Stack Dev Box\033[0m"
echo -e "\033[0;37m  ────────────────────────────────────────\033[0m"
echo -e "  Claude Code:   \033[1;32mclaude\033[0m"
echo -e "  Subscription:  \033[1;32mclaude login\033[0m  (if not using API key)"
echo -e "  Docker:        \033[1;32mdocker info\033[0m"
echo -e "  Codex:         \033[1;32mcodex\033[0m"
echo -e "  Files:         /files/ in browser"
echo -e "  Alembic:       \033[0;33malembic upgrade head\033[0m"
echo ""
BANNER

# ── File Browser ─────────────────────────────────────────────
FB_DB="/home/coder/.config/filebrowser/filebrowser.db"
filebrowser --database "$FB_DB" > /tmp/filebrowser.log 2>&1 &

# ── code-server (internal — auth handled by gateway) ─────────
code-server \
    --bind-addr 127.0.0.1:8081 \
    --auth none \
    --disable-telemetry \
    /home/coder > /tmp/code-server.log 2>&1 &

echo ""
echo "  VS Code  -> http://localhost:${PORT:-8080}"
echo "  Files    -> http://localhost:${PORT:-8080}/files/"
echo ""

# ── Auth gateway (single entry on :8080) ─────────────────────
exec python3 /home/coder/auth-gateway.py

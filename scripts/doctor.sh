#!/usr/bin/env bash
# Health check for a Hermes Anywhere deployment.
#
# Verifies: container status, dashboard reachability, OpenRouter key validity,
# disk usage, .env presence. Exits 0 if everything is healthy, 1 otherwise.
#
# Run on the VM (or locally with Docker Desktop):
#   bash scripts/doctor.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PASS=0
FAIL=0

ok()   { echo "  ✓ $*"; PASS=$((PASS+1)); }
warn() { echo "  ⚠ $*"; }
fail() { echo "  ✗ $*"; FAIL=$((FAIL+1)); }

section() { echo ""; echo "▶ $*"; }

# --- 1. Files in place ---
section "Files"
[[ -f docker-compose.yml ]] && ok "docker-compose.yml present" || fail "docker-compose.yml missing"
[[ -f .env ]] && ok ".env present" || fail ".env missing — copy from .env.example"

# --- 2. Docker available ---
section "Docker"
if command -v docker >/dev/null; then
  ok "docker CLI on PATH"
  if docker info >/dev/null 2>&1; then
    ok "docker daemon running"
  else
    fail "docker daemon not reachable"
  fi
else
  fail "docker not installed"
fi

# --- 3. Containers up ---
section "Containers"
for c in hermes-gateway hermes-dashboard; do
  STATUS=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null || echo missing)
  case "$STATUS" in
    running)   ok "$c: running" ;;
    restarting) fail "$c: restart loop — check 'docker logs $c'" ;;
    exited)    fail "$c: exited — check 'docker logs $c'" ;;
    missing)   fail "$c: not created — run 'docker compose up -d'" ;;
    *)         warn "$c: $STATUS" ;;
  esac
done

# --- 4. Dashboard reachable ---
section "Dashboard"
if curl -fsS --max-time 5 -o /dev/null http://127.0.0.1:9119/; then
  ok "dashboard responds on :9119"
else
  warn "dashboard not yet responding (first boot can take 60–90s)"
fi

# --- 5. OpenRouter key validity ---
section "OpenRouter API key"
if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  set -a; . ./.env; set +a
fi
if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
  CODE=$(curl -fsS -o /dev/null -w '%{http_code}' \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    https://openrouter.ai/api/v1/auth/key 2>/dev/null || echo 000)
  case "$CODE" in
    200) ok "OpenRouter key valid (auth/key returned 200)" ;;
    401) fail "OpenRouter key rejected (401)" ;;
    000) warn "could not reach openrouter.ai (offline?)" ;;
    *)   warn "OpenRouter auth/key returned HTTP $CODE" ;;
  esac
else
  fail "OPENROUTER_API_KEY not set in .env"
fi

# --- 6. Disk + state directory ---
section "Storage"
if [[ -d hermes-data ]]; then
  SIZE=$(du -sh hermes-data 2>/dev/null | awk '{print $1}')
  ok "hermes-data/ present (${SIZE:-?})"
else
  warn "hermes-data/ not yet created (first compose up creates it)"
fi
DISK_PCT=$(df . | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
if [[ -n "$DISK_PCT" ]]; then
  if [[ "$DISK_PCT" -lt 80 ]]; then
    ok "disk usage ${DISK_PCT}%"
  elif [[ "$DISK_PCT" -lt 90 ]]; then
    warn "disk usage ${DISK_PCT}% — consider cleanup"
  else
    fail "disk usage ${DISK_PCT}% — critical"
  fi
fi

# --- 7. Image version vs upstream ---
section "Version"
if scripts/check-update.sh --quiet; then
  ok "Hermes image up to date"
else
  case $? in
    1) warn "newer Hermes version available — run 'make check-update' for details" ;;
    *) warn "could not check upstream" ;;
  esac
fi

# --- Summary ---
echo ""
echo "─────────────────────────────"
echo "  $PASS passed, $FAIL failed"
echo "─────────────────────────────"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1

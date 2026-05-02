#!/usr/bin/env bash
# Daily notifier (run via systemd timer / cron) that posts when a new
# Hermes Agent version lands on Docker Hub.
#
# Notifications:
#   - Telegram (if TELEGRAM_BOT_TOKEN + TELEGRAM_ALLOWED_USERS in /opt/hermes-anywhere/.env)
#   - journald / stderr — always
#
# Idempotent: writes the last-notified version to a marker file so the user
# isn't pinged daily about the same release.

set -euo pipefail

REPO_ROOT="${HERMES_ANYWHERE_DIR:-/opt/hermes-anywhere}"
STATE_DIR="${HERMES_STATE_DIR:-/var/lib/hermes-anywhere}"
MARKER="$STATE_DIR/last-notified-version"

mkdir -p "$STATE_DIR"

cd "$REPO_ROOT"

# Run check-update.sh; capture the latest version it sees.
if "$REPO_ROOT/scripts/check-update.sh" --quiet; then
  echo "[$(date -Iseconds)] up-to-date"
  exit 0
fi

# check-update.sh exits 1 when newer is available. Re-fetch latest for the message.
LATEST=$(curl -fsSL \
  "https://hub.docker.com/v2/repositories/nousresearch/hermes-agent/tags?page_size=25&ordering=last_updated" \
  | jq -r '.results[].name' \
  | grep -E '^v[0-9]{4}\.[0-9]+\.[0-9]+$' \
  | sort -V \
  | tail -1)

CURRENT=$(grep -oE 'v[0-9]{4}\.[0-9]+\.[0-9]+' docker-compose.yml | head -1)

# Already notified? Skip.
if [[ -f "$MARKER" ]] && [[ "$(cat "$MARKER")" == "$LATEST" ]]; then
  echo "[$(date -Iseconds)] $LATEST already notified — skipping"
  exit 0
fi

MSG=$(cat <<EOF
🚀 Hermes Agent update available

Current:  $CURRENT
Latest:   $LATEST

Release notes:
https://github.com/NousResearch/hermes-agent/releases/tag/$LATEST

To update on this VM:
  cd $REPO_ROOT
  scripts/update.sh $LATEST
  git commit -am "Bump Hermes to $LATEST"
  docker compose pull && docker compose up -d
EOF
)

# Always log
echo "$MSG"

# Optional Telegram delivery
if [[ -f "$REPO_ROOT/.env" ]]; then
  # shellcheck disable=SC1091
  set -a; . "$REPO_ROOT/.env"; set +a
fi

if [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]] && [[ -n "${TELEGRAM_ALLOWED_USERS:-}" ]]; then
  CHAT_ID="${TELEGRAM_ALLOWED_USERS%%,*}"   # first allowed user
  curl -fsS -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${MSG}" \
    -d "disable_web_page_preview=true" \
    >/dev/null && echo "[$(date -Iseconds)] notified via Telegram"
fi

echo "$LATEST" > "$MARKER"

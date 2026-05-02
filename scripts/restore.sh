#!/usr/bin/env bash
# Restore hermes-data/ from an encrypted backup created by scripts/backup.sh.
#
# Usage:
#   BACKUP_PASSPHRASE='...' scripts/restore.sh backups/hermes-data.YYYY-MM-DD.tgz.gpg
#
# Stops Hermes containers, replaces hermes-data/, restarts. The current
# hermes-data/ is moved aside to hermes-data.before-restore.<stamp>/ — not
# deleted — so you can roll back if the restore is wrong.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FILE="${1:-}"
[[ -n "$FILE" ]] || { echo "Usage: $0 path/to/hermes-data.YYYY-MM-DD.tgz.gpg" >&2; exit 1; }
[[ -f "$FILE" ]] || { echo "File not found: $FILE" >&2; exit 1; }

if [[ -z "${BACKUP_PASSPHRASE:-}" ]]; then
  echo "BACKUP_PASSPHRASE not set." >&2
  exit 1
fi

command -v gpg >/dev/null || { echo "gpg not installed"; exit 1; }
command -v docker >/dev/null || { echo "docker not installed"; exit 1; }

echo "Stopping Hermes containers…"
docker compose down

if [[ -d hermes-data ]]; then
  STAMP=$(date +%Y-%m-%d-%H%M)
  AWAY="hermes-data.before-restore.${STAMP}"
  echo "Moving current hermes-data/ → $AWAY/"
  mv hermes-data "$AWAY"
fi

echo "Decrypting + extracting $FILE…"
gpg --batch --yes --decrypt --passphrase-fd 3 "$FILE" 3<<<"$BACKUP_PASSPHRASE" \
  | tar -xzf -

[[ -d hermes-data ]] || { echo "Extraction did not produce hermes-data/ — aborting"; exit 1; }

echo "Starting Hermes containers…"
docker compose up -d

echo ""
echo "✓ Restore complete."
echo "  Old state preserved at: $AWAY/ (delete when you're confident)"

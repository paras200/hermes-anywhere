#!/usr/bin/env bash
# Encrypted backup of hermes-data/ — the agent's entire state (skills, memory,
# auth tokens, logs, Curator reports).
#
# Usage:
#   BACKUP_PASSPHRASE='strong-passphrase' scripts/backup.sh
#
# Output:
#   backups/hermes-data.YYYY-MM-DD-HHMM.tgz.gpg
#
# Restore with: scripts/restore.sh <file>
#
# Tip: store BACKUP_PASSPHRASE in your password manager. Without it, the
# backup is unrecoverable.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

command -v gpg >/dev/null || { echo "gpg not installed (apt install gnupg / brew install gnupg)"; exit 1; }

[[ -d hermes-data ]] || { echo "hermes-data/ not found — nothing to back up"; exit 1; }

if [[ -z "${BACKUP_PASSPHRASE:-}" ]]; then
  echo "BACKUP_PASSPHRASE not set." >&2
  echo "Generate one:  openssl rand -base64 32" >&2
  echo "Then:          export BACKUP_PASSPHRASE='...' && scripts/backup.sh" >&2
  exit 1
fi

mkdir -p backups
STAMP=$(date +%Y-%m-%d-%H%M)
OUT="backups/hermes-data.${STAMP}.tgz.gpg"

echo "Creating encrypted backup → $OUT"

# tar with --exclude for noisy/regenerable files; pipe directly into gpg.
tar --exclude='hermes-data/logs/*.log' \
    --exclude='hermes-data/cache' \
    -czf - hermes-data \
  | gpg --batch --yes --symmetric --cipher-algo AES256 \
        --passphrase-fd 3 \
        --output "$OUT" \
  3<<<"$BACKUP_PASSPHRASE"

SIZE=$(du -h "$OUT" | awk '{print $1}')
echo "✓ Backup written: $OUT ($SIZE)"
echo ""
echo "Off-host options:"
echo "  scp $OUT user@backup-host:/path/"
echo "  aws s3 cp $OUT s3://your-bucket/"
echo "  rclone copy $OUT remote:hermes-backups/"

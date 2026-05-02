#!/usr/bin/env bash
# Check Docker Hub for newer Hermes Agent images than the pinned version.
#
# Exit codes:
#   0  — pinned version is current
#   1  — newer version available (prints summary + release notes link)
#   2  — error (Docker Hub unreachable, no pinned version found, etc.)
#
# Usage: scripts/check-update.sh [--quiet]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose.yml"
QUIET=0

[[ "${1:-}" == "--quiet" ]] && QUIET=1

log() { [[ $QUIET -eq 1 ]] || echo "$@"; }
die() { echo "ERROR: $*" >&2; exit 2; }

command -v jq >/dev/null   || die "jq is required (brew install jq / apt install jq)"
command -v curl >/dev/null || die "curl is required"

[[ -f "$COMPOSE_FILE" ]] || die "docker-compose.yml not found at $COMPOSE_FILE"

CURRENT=$(grep -oE 'v[0-9]{4}\.[0-9]+\.[0-9]+' "$COMPOSE_FILE" | head -1)
[[ -n "$CURRENT" ]] || die "could not parse current version from $COMPOSE_FILE"

log "Current pinned version: $CURRENT"

# Docker Hub: list tags by last_updated descending; ignore non-version tags (latest, sha-*, etc.)
LATEST=$(curl -fsSL \
  "https://hub.docker.com/v2/repositories/nousresearch/hermes-agent/tags?page_size=25&ordering=last_updated" \
  | jq -r '.results[].name' \
  | grep -E '^v[0-9]{4}\.[0-9]+\.[0-9]+$' \
  | sort -V \
  | tail -1) || die "could not query Docker Hub"

[[ -n "$LATEST" ]] || die "no version-shaped tags found in Docker Hub response"

log "Latest published version: $LATEST"

if [[ "$CURRENT" == "$LATEST" ]]; then
  log "✓ Up to date."
  exit 0
fi

# Newer version exists — print the GitHub release notes URL.
log ""
log "✗ Update available: $CURRENT → $LATEST"
log ""
log "  Release notes: https://github.com/NousResearch/hermes-agent/releases/tag/$LATEST"
log "  Apply with:    scripts/update.sh $LATEST"
exit 1

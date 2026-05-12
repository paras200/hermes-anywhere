#!/usr/bin/env bash
# Check Docker Hub for a newer Hermes Agent image than what is currently
# pulled locally. Upstream switched from `vYYYY.M.D` tags to a `latest` +
# `sha-<commit>` scheme, so we compare image digests rather than version
# strings.
#
# Exit codes:
#   0  — local image matches the latest published digest
#   1  — a newer image is available (prints summary + commands)
#   2  — error (Docker Hub unreachable, no digest found, etc.)
#
# Usage: scripts/check-update.sh [--quiet]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose.yml"
QUIET=0
IMAGE="nousresearch/hermes-agent"

[[ "${1:-}" == "--quiet" ]] && QUIET=1

log() { [[ $QUIET -eq 1 ]] || echo "$@"; }
die() { echo "ERROR: $*" >&2; exit 2; }

command -v jq >/dev/null   || die "jq is required (brew install jq / apt install jq)"
command -v curl >/dev/null || die "curl is required"

[[ -f "$COMPOSE_FILE" ]] || die "docker-compose.yml not found at $COMPOSE_FILE"

# Read the pinned tag (defaults to `latest` when HERMES_VERSION is unset/empty).
TAG="${HERMES_VERSION:-}"
if [[ -z "$TAG" && -f "$REPO_ROOT/.env" ]]; then
  TAG=$(grep -E '^HERMES_VERSION=' "$REPO_ROOT/.env" | tail -1 | cut -d= -f2- || true)
fi
[[ -n "$TAG" ]] || TAG="latest"
log "Configured tag: $TAG"

# Latest digest on Docker Hub for that tag (multi-arch index digest).
REMOTE_DIGEST=$(curl -fsSL \
  "https://hub.docker.com/v2/repositories/$IMAGE/tags/$TAG" \
  | jq -r '.digest // empty') || die "could not query Docker Hub for tag '$TAG'"
[[ -n "$REMOTE_DIGEST" ]] || die "no digest found for tag '$TAG' on Docker Hub"
log "Latest published digest: $REMOTE_DIGEST"

# Locally pulled digest (if image is present). Prefer RepoDigests.
LOCAL_DIGEST=$(docker image inspect "$IMAGE:$TAG" \
  --format '{{range .RepoDigests}}{{.}}{{"\n"}}{{end}}' 2>/dev/null \
  | head -1 | awk -F'@' '{print $2}' || true)

if [[ -z "$LOCAL_DIGEST" ]]; then
  log ""
  log "✗ No local image for $IMAGE:$TAG yet."
  log "  Pull with:  docker compose pull && docker compose up -d"
  exit 1
fi
log "Local image digest:      $LOCAL_DIGEST"

if [[ "$LOCAL_DIGEST" == "$REMOTE_DIGEST" ]]; then
  log "✓ Up to date."
  exit 0
fi

log ""
log "✗ Update available for $IMAGE:$TAG"
log "  local : $LOCAL_DIGEST"
log "  remote: $REMOTE_DIGEST"
log ""
log "  Apply with:  docker compose pull && docker compose up -d"
log "  Or:          make install"
exit 1

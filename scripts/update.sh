#!/usr/bin/env bash
# Bump the Hermes Agent tag everywhere it appears.
#
# Usage:
#   scripts/update.sh <tag>
#
# <tag> may be:
#   - `latest`                     (default — pulled fresh on each install)
#   - `vYYYY.M.D`                  (legacy date-version tag)
#   - `sha-<commit>`               (specific build for reproducibility)
#
# Updates: docker-compose.yml, .env.example, terraform/<provider>/variables.tf
# Use --dry-run to preview changes without writing.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
NEW=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,13p' "$0" | sed 's/^# //; s/^#//'
      exit 0
      ;;
    -*) echo "Unknown flag: $arg" >&2; exit 1 ;;
    *) NEW="$arg" ;;
  esac
done

[[ -n "$NEW" ]] || { echo "Usage: $0 <tag> [--dry-run]   (e.g. latest, v2026.4.30, sha-abc1234)" >&2; exit 1; }

[[ "$NEW" =~ ^(latest|v[0-9]{4}\.[0-9]+\.[0-9]+|sha-[0-9a-f]{7,40})$ ]] \
  || { echo "Tag must be 'latest', 'vYYYY.M.D', or 'sha-<commit>'. Got: $NEW" >&2; exit 1; }

cd "$REPO_ROOT"

OLD=$(grep -oE 'HERMES_VERSION:-[A-Za-z0-9.-]+' docker-compose.yml | head -1 | cut -d- -f2-)
[[ -n "$OLD" ]] || { echo "Could not detect current tag in docker-compose.yml" >&2; exit 1; }

if [[ "$OLD" == "$NEW" ]]; then
  echo "Already on $NEW. Nothing to do."
  exit 0
fi

# Files to update:
mapfile -t FILES < <(
  printf '%s\n' \
    docker-compose.yml \
    .env.example \
    $(find terraform -name 'variables.tf' | sort)
)

echo "Bumping $OLD → $NEW in:"
printf '  %s\n' "${FILES[@]}"

if [[ $DRY_RUN -eq 1 ]]; then
  echo ""
  echo "(dry-run — diff preview)"
  for f in "${FILES[@]}"; do
    diff <(cat "$f") <(sed "s|$OLD|$NEW|g" "$f") || true
  done
  exit 0
fi

# Use sed -i with a portable backup-and-delete pattern (works on both BSD/macOS and GNU sed).
for f in "${FILES[@]}"; do
  sed -i.bak "s|$OLD|$NEW|g" "$f" && rm -f "$f.bak"
done

echo ""
echo "Done. Next steps:"
echo "  1. Review changes:  git diff"
echo "  2. Commit:          git commit -am \"Bump Hermes to $NEW\""
echo "  3. Locally:         make install"
echo "  4. On the VM:       cd /opt/hermes-anywhere && git pull && sudo systemctl restart hermes"

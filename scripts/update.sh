#!/usr/bin/env bash
# Bump the Hermes Agent version everywhere it appears.
#
# Usage:
#   scripts/update.sh vYYYY.M.D
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
      sed -n '2,9p' "$0" | sed 's/^# //; s/^#//'
      exit 0
      ;;
    v*) NEW="$arg" ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

[[ -n "$NEW" ]] || { echo "Usage: $0 vYYYY.M.D [--dry-run]" >&2; exit 1; }

[[ "$NEW" =~ ^v[0-9]{4}\.[0-9]+\.[0-9]+$ ]] \
  || { echo "Version must look like 'v2026.4.30'. Got: $NEW" >&2; exit 1; }

cd "$REPO_ROOT"

OLD=$(grep -oE 'v[0-9]{4}\.[0-9]+\.[0-9]+' docker-compose.yml | head -1)
[[ -n "$OLD" ]] || { echo "Could not detect current version in docker-compose.yml" >&2; exit 1; }

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
echo "  3. On the VM:       cd /opt/hermes-anywhere && git pull && docker compose pull && docker compose up -d"

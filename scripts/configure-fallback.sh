#!/usr/bin/env bash
# Append a fallback_providers entry to the VM's hermes-data/config.yaml so the
# agent fails over to a backup model when the primary errors out.
#
# Usage:
#   scripts/configure-fallback.sh <model-slug> [provider] [base-url]
#
#   model-slug  Required. Anything OpenRouter accepts; defaults to free.
#   provider    Optional. Default: openrouter.
#   base-url    Optional. Default: https://openrouter.ai/api/v1.
#
# Empty model-slug = no-op (so cloud-init can pass through without branching).
#
# Idempotent: skips the write if fallback_providers already exists with this
# exact model. Safe to re-run.

set -euo pipefail

MODEL="${1:-}"
PROVIDER="${2:-openrouter}"
BASE_URL="${3:-https://openrouter.ai/api/v1}"

[[ -z "$MODEL" ]] && { echo "configure-fallback: model empty, skipping."; exit 0; }

CONFIG="/opt/hermes-anywhere/hermes-data/config.yaml"

# Hermes creates config.yaml on first container start. Wait up to 3 minutes
# for it to appear before giving up — this keeps cloud-init from hanging if
# something else has gone wrong.
for _ in $(seq 1 90); do
  [[ -f "$CONFIG" ]] && break
  sleep 2
done
[[ -f "$CONFIG" ]] || { echo "configure-fallback: $CONFIG never appeared, skipping." >&2; exit 0; }

if grep -qE "^fallback_providers:" "$CONFIG" && grep -qF "model: $MODEL" "$CONFIG"; then
  echo "configure-fallback: $MODEL already present, skipping."
  exit 0
fi

cat >> "$CONFIG" <<EOF
fallback_providers:
  - provider: $PROVIDER
    model: $MODEL
    base_url: $BASE_URL
EOF

# Restart the gateway so the new chain is loaded. Dashboard doesn't need it
# for inference, but restarting both keeps them on the same config snapshot.
( cd /opt/hermes-anywhere && docker compose restart )
echo "configure-fallback: $MODEL added and gateway restarted."

# Choosing an OpenRouter model for Hermes

Hermes routes everything — skill creation, curator runs, tool calls, dashboard chats — through one model. Quality compounds, so don't settle on something cheap-but-dumb.

## TL;DR

**Default: `openai/gpt-oss-120b:free`** — currently the strongest free agent-capable model on OpenRouter (May 2026).

**Pre-requisite for any 24/7 setup:** add **$10 of credit** to your OpenRouter account. Even though you're using `:free` model slugs (no per-token cost), a $10 lifetime top-up unlocks 1,000 free-model requests/day instead of the default 50/day. Without it the gateway throttles within hours.

## Why GPT-OSS 120B

| Criterion | gpt-oss-120b | Why it matters |
|---|---|---|
| MMLU-Pro | **90.0%** | beats DeepSeek R1 (85.0), GLM-4.5 (84.6), Qwen3 Thinking (84.4), Kimi K2 (81.1) |
| Native tool use | ✅ function calling, structured outputs | Hermes' core loop |
| Reasoning depth | Configurable, full CoT access | Curator/skill-grading benefits from deeper passes |
| Context | 131,072 tokens | comfortable above Hermes' 64 K minimum |
| Designed for | "agentic, general-purpose production use" | exactly Hermes' use case |

## Alternatives (priority order)

1. **`openrouter/free`** — auto-router. Best hedge against single-model outages: if 120B has a rough hour, it falls back to another tool-calling-capable free model. Use as primary if you've seen 120B flake.
2. **`z-ai/glm-4.5-air:free`** — 131 K context, hybrid thinking/non-thinking modes. Solid backup.
3. **`google/gemma-4-31b-it:free`** — 256 K context, native function calling, multimodal. Big context appeals for long skill libraries; raw agent quality below 120B.
4. **`minimax/minimax-m2.5:free`** — 197 K context, agent-optimized. Less reliability data than the above.

## Models to avoid as primary

- Anything <64 K context — Hermes will reject at startup
- Models flagged "preview" or "experimental" — availability rotates

## Setting the model

The model slug lives in `hermes-data/.env` (managed by the agent). To change:

1. Open the dashboard at `http://<vm-ip>:9119`
2. Settings → Provider config → set model to e.g. `openai/gpt-oss-120b:free`
3. **Or** via Telegram: `/model openai/gpt-oss-120b:free --provider openrouter --global`
4. **Or** edit `hermes-data/.env` on the VM and restart the gateway

## Rate limits at a glance

| OpenRouter tier | Free-model RPM | Free-model RPD |
|---|---|---|
| No credits | 20 | **50** |
| ≥$10 lifetime | 20 | **1,000** |

The $10 is the single biggest unlock. Failed requests count toward the daily quota.

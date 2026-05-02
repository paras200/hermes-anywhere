# Hosting cost analysis

Researched May 2026 for a Hermes Agent deployment (~2 vCPU, 4 GB RAM target).

## Summary table

| Tier | Provider | Plan | Specs | Monthly | Notes |
|---|---|---|---|---|---|
| **Free** | Oracle Cloud Always Free | VM.Standard.A1.Flex | 4 OCPU + 24 GB ARM | **$0** | Permanent. ARM. Idle reclaim if 95th-pct CPU <20% for 7 days. |
| **Free** | Self-host on Pi 5 (8 GB) | — | 4-core ARM + 8 GB | **~$0.20–0.30** electricity (one-time ~$110 hardware) | Truly permanent. Use Tailscale for remote access. |
| **Cheap paid** | RackNerd | 4 GB KVM | 3 vCPU + 4 GB + 105 GB | **~$3** (annual $35.88/yr) | Cheapest credible. Annual billing only. |
| **Cheap paid** | Hetzner | CX22 | 2 vCPU + 4 GB + 40 GB NVMe | **€4.49 (~$5)** + VAT | Best price/performance. EU + US regions. |
| **Cheap paid** | Contabo | Cloud VPS 10 | 3 vCPU + 8 GB + 75 GB NVMe | **$4.95** | Generous RAM, inconsistent I/O. |
| **Cheap paid** | Netcup | VPS 1000 ARM G11 | 6 cores ARM + 8 GB + 256 GB | **€5.26 (~$5.70)** + VAT | Strong spec, EU only. |
| **Mainstream** | GCP | e2-small | 2 vCPU shared + 2 GB | **~$13** | Use only if already on GCP. |
| **Mainstream** | AWS Lightsail | medium_3_0 | 2 vCPU + 4 GB + 80 GB | **$20** | Watch snapshot/static-IP/egress fees. |
| **Mainstream** | DigitalOcean | s-2vcpu-4gb | 2 vCPU + 4 GB + 80 GB | **$20–24** | Polished, predictable. |
| **Mainstream** | Vultr | High Perf AMD 4 GB | 2 vCPU + 4 GB + 100 GB NVMe | **$24** | EPYC-Genoa, NVMe. |

## Why these recommendations

- **Permanent zero-cost**: Oracle Always Free is the obvious choice if you can get an account approved. ARM-only is fine — Hermes' Docker image is multi-arch.
- **Cheapest reliable paid**: Hetzner CX22 at ~$5/mo. Apr 2026 prices went up ~36% but still beats every named alternative.
- **Match-your-stack**: GCP/AWS/DO if you've already standardized on that cloud. Pay the convenience premium of $10–20/mo.

## What you don't pay for

- LLM inference: $0 with OpenRouter `:free` model slugs (one-time $10 top-up recommended for 1,000 req/day rate-limit unlock instead of 50/day).
- Bandwidth: every option above includes generous egress (1–20 TB).
- Storage: included in plan.

## Migration

State lives in `hermes-data/`. Switching providers is a `tar`, `scp`, untar — nothing is locked to a vendor. See `AGENTS.md` "Migrate to a different cloud."

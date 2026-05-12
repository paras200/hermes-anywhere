# Hermes Anywhere

> **Deploy the [Nous Research Hermes Agent](https://github.com/NousResearch/hermes-agent) — a self-improving AI agent — to any cloud, in one `terraform apply`.**

Cloud-agnostic Terraform + Docker setup for running Hermes 24/7 on the cheapest infrastructure that fits you: Oracle Always Free ($0), Hetzner (€4.49/mo), GCP, AWS Lightsail, or DigitalOcean. Same image, same data layout, same dashboard everywhere.

**Keywords:** hermes agent · self-improving AI agent · self-hosted AI agent · autonomous AI agent · Nous Research · OpenRouter · Terraform · Docker · multi-cloud · cloud-agnostic · Hetzner · Oracle Cloud Always Free · DigitalOcean · AWS Lightsail · GCP · LLM · agent infrastructure · IaC · always-on AI · Telegram bot · Claude · GPT-OSS

---

## Why this exists

Hermes Agent is the only AI agent with a built-in learning loop — it creates skills from experience, persists what works, and builds a deepening model of who you are across sessions. To get value from that you need it **always running**, which means a server. This repo is the cheapest, most portable way to do that.

| Feature | Hermes Anywhere |
|---|---|
| Bring-your-own cloud | ✅ 5 providers supported |
| Free-tier deployable | ✅ Oracle Always Free (4 OCPU / 24 GB ARM) |
| One-command deploy | ✅ `terraform apply` |
| Free LLM out of the box | ✅ OpenRouter `:free` models (GPT-OSS 120B default) |
| Survives reboot | ✅ systemd unit, auto-recover on boot |
| Portable state | ✅ everything in `hermes-data/`, just rsync to migrate |

## Pick your cloud

```
                   Oracle ──→ $0/mo  permanent, ARM, 24 GB RAM
                   Hetzner ──→ €4.49 best paid price/performance
hermes-anywhere ──┤  GCP ──→ ~$13   if already on Google Cloud
                   AWS LS ──→ $20    if already on AWS
                   DO ─────→ $24    polished and mainstream
```

Full breakdown in [`docs/COSTS.md`](docs/COSTS.md). Recommended path: try Oracle Always Free first, fall back to Hetzner.

## Quick start (any cloud)

**Prerequisites:**
- `terraform` ≥ 1.5
- An SSH key (`ssh-keygen -t ed25519` if you don't have one)
- An [OpenRouter API key](https://openrouter.ai/keys) (free model slugs work without credits, but a one-time **$10 top-up** raises free-model rate limits from 50/day → 1,000/day — strongly recommended for an always-on agent)
- Cloud-specific credentials (see the per-provider README in `terraform/<provider>/`)

**Deploy to a cloud VM:**

```bash
git clone https://github.com/paras200/hermes-anywhere.git
cd hermes-anywhere/terraform/hetzner   # or oracle / gcp / aws-lightsail / digitalocean

cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: API token, ssh_public_key, openrouter_api_key

terraform init
terraform apply
```

In ~60–90 seconds, `terraform output dashboard_url` is reachable in your browser. The VM pulls `nousresearch/hermes-agent:latest` on first boot, so you always get the current image.

**Run locally (Docker Compose only):**

```bash
git clone https://github.com/paras200/hermes-anywhere.git
cd hermes-anywhere
make install   # creates .env, pulls latest image, starts containers
# edit .env to add OPENROUTER_API_KEY, then: docker compose restart
```

Dashboard at <http://localhost:9119>. `make update` later to pull a newer image.

## Day-2 operations

Once Hermes is up, the repo is also a full operations toolkit:

| Command | What it does |
|---|---|
| `make install` | First-time setup — copy `.env`, pull latest image, start containers |
| `make update` | Pull the newest image digest and restart (no file edits) |
| `make doctor` | Health check — containers, dashboard, OpenRouter key, disk |
| `make check-update` | Compares local vs Docker Hub digest for the configured tag |
| `make pin TAG=…` | Pin all files to a specific tag (`latest`, `vYYYY.M.D`, or `sha-…`) |
| `make backup` | GPG-encrypted tarball of `hermes-data/` |
| `make restore FILE=…` | Restore from a backup tarball |
| `sudo make install-cron` | Install systemd timer for daily upstream-version checks (Telegram + journal) |

Plus, this repo includes a daily GitHub Action ([`ci/check-upstream.yml`](ci/check-upstream.yml)) that auto-opens an issue when Nous Research publishes a new Hermes release. See [`ci/README.md`](ci/README.md) for one-line activation.

Full walkthrough: [`docs/OPERATIONS.md`](docs/OPERATIONS.md).

## Repo layout

```
hermes-anywhere/
├── README.md                 # this file
├── AGENTS.md                 # detailed execution guide for AI agents
├── docker-compose.yml        # Hermes gateway + dashboard
├── .env.example              # env-var template
├── chatbox.py                # OpenRouter REPL for quick model testing
├── Makefile                  # ops entry points — run `make help`
├── cloud-init/
│   └── hermes.cloud-config.yaml.tpl   # provider-agnostic VM bootstrap
├── scripts/
│   ├── check-update.sh       # poll Docker Hub for newer Hermes
│   ├── update.sh             # atomic version bump
│   ├── notify-update.sh      # daily systemd/Telegram notifier
│   ├── install-cron.sh       # set up the systemd timer
│   ├── doctor.sh             # 7-point health check
│   ├── backup.sh             # GPG-encrypted hermes-data/ tarball
│   └── restore.sh            # rollback-safe restore
├── ci/                       # GitHub Actions (move into .github/workflows/ to activate)
│   ├── check-upstream.yml    # daily auto-issue on new upstream release
│   └── terraform-validate.yml # PR check for HCL
├── terraform/
│   ├── README.md             # picks-your-cloud guide
│   ├── hetzner/              # CX22, €4.49/mo
│   ├── oracle/               # A1.Flex ARM, $0/mo
│   ├── gcp/                  # e2-small, ~$13/mo
│   ├── aws-lightsail/        # medium_3_0, $20/mo
│   └── digitalocean/         # s-2vcpu-4gb, $24/mo
├── skills/
│   └── alpha-desk/           # example skill — equity research workflow
├── scripts/
└── docs/
    ├── COSTS.md              # full cost comparison
    ├── MODEL_SELECTION.md    # which OpenRouter model to use
    ├── SKILLS.md             # how to add your own skills
    └── TROUBLESHOOTING.md
```

## The default model

Configured to use `openai/gpt-oss-120b:free` on OpenRouter — currently the strongest free agent-capable model (90.0% MMLU-Pro, native tool calling, 131 K context). See [`docs/MODEL_SELECTION.md`](docs/MODEL_SELECTION.md) for the full rationale and alternatives.

## Adding skills

Skills are how Hermes learns. The included [`skills/alpha-desk/`](skills/alpha-desk/) is a worked example showing the structure: a `SKILL.md` charter, supporting `references/`, and executable `scripts/`. Drop your own skill folder in `skills/`, copy it onto the VM into `hermes-data/skills/`, and Hermes will pick it up. See [`docs/SKILLS.md`](docs/SKILLS.md).

## Operating costs at a glance

| Component | Cost |
|---|---|
| Compute (Oracle Always Free) | **$0** |
| Compute (Hetzner CX22) | **€4.49** |
| LLM inference (OpenRouter `:free`) | **$0** + one-time **$10** for higher rate limits |
| Storage (included) | $0 |
| **Total — cheapest path** | **$0–10 one-time** |
| **Total — most reliable paid path** | **~$5/mo** |

## Documentation

- [`docs/OPERATIONS.md`](docs/OPERATIONS.md) — **the walkthrough**: deploy, update, back up, restore, migrate
- [`AGENTS.md`](AGENTS.md) — explicit execution guide for AI agents (Claude Code, Cursor, etc.)
- [`docs/COSTS.md`](docs/COSTS.md) — full cloud cost analysis
- [`docs/MODEL_SELECTION.md`](docs/MODEL_SELECTION.md) — OpenRouter free model comparison
- [`docs/SKILLS.md`](docs/SKILLS.md) — building skills, with `alpha-desk` as worked example
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — common failure modes
- [`terraform/README.md`](terraform/README.md) — Terraform module overview

## Acknowledgements

- [Nous Research](https://nousresearch.com/) for [Hermes Agent](https://github.com/NousResearch/hermes-agent) itself
- [OpenRouter](https://openrouter.ai/) for free-tier LLM access

## License

MIT — see [`LICENSE`](LICENSE).

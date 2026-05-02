# AGENTS.md — Execution guide for AI agents

This document is written for AI coding agents (Claude Code, Cursor, GitHub Copilot Chat, OpenAI Codex, etc.) tasked with **deploying, maintaining, or extending** Hermes Anywhere on behalf of a human user. It is intentionally prescriptive: explicit steps, decision trees, and verification commands.

---

## What this repo is

A turnkey, Terraform-based deployment for **[Nous Research Hermes Agent](https://github.com/NousResearch/hermes-agent)** — a self-improving AI agent that runs as a long-lived background service. The repo:

1. Pins a specific Hermes Docker image version
2. Wraps it in a `docker compose` file (gateway + dashboard)
3. Provisions a VM on one of five clouds via Terraform
4. Bootstraps the VM via cloud-init (installs Docker, clones repo, starts compose, enables systemd auto-start)

You will mostly work with: Terraform variables, `.env` values, and the cloud-init template.

---

## Decision tree: which cloud?

When the user has not specified, ask them. If they refuse to choose, default in this order:

1. **Oracle Always Free** — if the user has not previously been rejected by Oracle's signup fraud-check. Permanent $0.
2. **Hetzner** — best paid price/performance. €4.49/mo. Defaults are sane.
3. **GCP** — if the user is already invested in Google Cloud (existing project, IAM, billing).
4. **AWS Lightsail** — if user is on AWS.
5. **DigitalOcean** — only if user explicitly prefers it.

**Disqualifiers:**
- Oracle: ARM-only via free tier. Hermes image is `arm64`-compatible, so this is fine. But Oracle reclaims VMs idle <20% CPU over 7 days — verify Hermes' workload before committing.
- GCP `e2-micro` (the actual free-tier GCE shape): only 1 GB RAM. **Do not use.** Hermes needs 2–4 GB minimum.

---

## Standard deployment procedure

### 1. Pre-flight

```bash
# Required tools
terraform version    # need >= 1.5
git --version
ssh-keygen -t ed25519 -C "user@host" -f ~/.ssh/id_ed25519   # if missing
```

### 2. Gather secrets from the user

Ask for, and verify presence of, **all** of these before running `terraform apply`:

| Variable | Where to get | Required? |
|---|---|---|
| `openrouter_api_key` | https://openrouter.ai/keys | **Yes** |
| `ssh_public_key` | `cat ~/.ssh/id_ed25519.pub` | **Yes** |
| Cloud-specific creds | See `terraform/<provider>/README.md` | **Yes** |
| `telegram_bot_token` | @BotFather on Telegram | Optional |
| `telegram_allowed_users` | @userinfobot on Telegram | Required if bot token set |

**Never** print secret values in chat output. Use `grep -c VAR terraform.tfvars` to verify presence.

### 3. Apply

```bash
cd terraform/<provider>
cp terraform.tfvars.example terraform.tfvars
# user edits terraform.tfvars

terraform init
terraform plan       # review for surprises
terraform apply
```

### 4. Verify deployment

After apply succeeds:

```bash
# 1. Public IP printed?
terraform output public_ipv4

# 2. SSH reachable (after ~30s)?
ssh -o StrictHostKeyChecking=accept-new $(terraform output -raw ssh_command | sed 's/^ssh //')  "echo ok"

# 3. Hermes containers up (after ~90s)?
ssh ... "sudo docker ps"
# expect: hermes-gateway and hermes-dashboard, both 'Up'

# 4. Dashboard responding?
curl -sf "$(terraform output -raw dashboard_url)" -o /dev/null && echo OK || echo NOT_READY
```

If step 3 shows containers in `Restarting` state, that's almost always a missing or wrong `OPENROUTER_API_KEY`. SSH in, `cd /opt/hermes-anywhere`, check `cat .env`, fix, then `sudo docker compose restart gateway`.

---

## Editing the cloud-init template

`cloud-init/hermes.cloud-config.yaml.tpl` is rendered by every Terraform module via `templatefile()`. If you change it:

1. Existing VMs are **not** reconfigured automatically. You'd need to `terraform taint <resource>` or destroy+apply.
2. Variables in `${...}` placeholders must be passed by every provider's `main.tf`. If you add one, update **all five** modules.
3. Test the rendered output with: `terraform plan` shows the templated user_data.

---

## Editing Terraform modules

The five modules are intentionally not DRY'd into a single shared module — each cloud has different network/firewall/IAM primitives, and abstracting that costs more readability than it saves.

When you need to add a feature (e.g., a static IP, a backup snapshot policy):

1. Implement it in **one** provider first (suggest: hetzner — fewest moving parts).
2. Get user sign-off that it works.
3. Port to the other four.

Keep variable names identical across providers. The shared cloud-init template depends on this.

---

## Adding a skill

Skills live in `skills/<name>/`. Required structure:

```
skills/<name>/
├── SKILL.md          # charter — what the skill does, when to invoke it
├── references/       # markdown reference docs the skill can read
└── scripts/          # executable helpers (Python/bash)
```

See [`skills/alpha-desk/`](skills/alpha-desk/) for a complete example.

To deploy a new skill to a running Hermes:

```bash
# Copy from repo to VM's hermes-data
scp -r skills/<name> user@vm:/opt/hermes-anywhere/hermes-data/skills/

# Hermes picks it up automatically; the curator will grade it within a 7-day cycle.
```

---

## Updating the Hermes image

Hermes releases roughly every 1–2 weeks. To bump:

1. Find the latest tag at https://hub.docker.com/r/nousresearch/hermes-agent/tags
2. Read release notes at https://github.com/NousResearch/hermes-agent/releases for breaking changes
3. Update **two** places:
   - `docker-compose.yml` default: `${HERMES_VERSION:-vYYYY.M.D}`
   - All five `terraform/<provider>/variables.tf`: `default = "vYYYY.M.D"` for `hermes_version`
4. Commit, push, then on the running VM:
   ```bash
   cd /opt/hermes-anywhere
   sudo git pull
   sudo docker compose pull && sudo docker compose up -d
   ```

Never use `:latest`. Pinning is mandatory.

---

## Common operations cookbook

### Tail logs
```bash
sudo docker compose logs -f --tail=100
```

### Restart after a crash
```bash
sudo docker compose restart
```

### Hermes shell (inside container)
```bash
sudo docker exec -it --user hermes hermes-gateway bash -c \
  'cd /opt/hermes && source .venv/bin/activate && exec bash'
```

### Backup `hermes-data/`
```bash
sudo tar -czf hermes-data-$(date +%F).tgz hermes-data/
# move off-box; encrypt with `gpg -c` if storing externally
```

### Migrate to a different cloud
```bash
# On source VM
sudo tar -czf /tmp/hermes-data.tgz -C /opt/hermes-anywhere hermes-data/
scp source:/tmp/hermes-data.tgz local:

# Provision destination via terraform/<new-provider>
# After bootstrap completes, before first run: stop hermes, replace data, restart.
ssh dest "sudo systemctl stop hermes"
scp hermes-data.tgz dest:/tmp/
ssh dest "sudo tar -xzf /tmp/hermes-data.tgz -C /opt/hermes-anywhere/"
ssh dest "sudo systemctl start hermes"
```

---

## What NOT to do

- ❌ Do not commit `terraform.tfvars`, `.env`, `*.tfstate`, or any `*.pem` / `*.key` file. `.gitignore` covers all of these — verify before commit.
- ❌ Do not use `:latest` for the Hermes image tag.
- ❌ Do not weaken the firewall rules (`0.0.0.0/0` for SSH/dashboard) on a long-lived deployment. The example tfvars use it for first-run convenience only — narrow before going permanent.
- ❌ Do not skip the OpenRouter $10 top-up on a 24/7 deployment — the 50/day free-model rate limit will throttle the agent within hours.
- ❌ Do not run `terraform destroy` without first backing up `hermes-data/` if the user has skills or memory they want to keep.

---

## When the user asks for a new cloud provider

The pattern to follow:

1. Create `terraform/<new-provider>/{main,variables,outputs,terraform.tfvars.example,README}.{tf,tfvars.example,md}`
2. Use `terraform/hetzner/` as the structural template
3. Provider-specific resources: VM, public IP, firewall/security-group, SSH key
4. Render `../cloud-init/hermes.cloud-config.yaml.tpl` exactly the same way
5. Output: `public_ipv4`, `ssh_command`, `dashboard_url`
6. Update `terraform/README.md` cloud table
7. Update `README.md` cloud breakdown
8. Update this file's decision tree

---

## Repo conventions

- Markdown: GitHub-flavored, no emojis in committed docs unless asking the user first.
- Terraform: HCL formatting via `terraform fmt -recursive` before commit.
- Commits: imperative subject ("Add Vultr Terraform module"), reference issues if any.
- Public-facing docs (README, this file) optimize for discoverability + clarity. Do not add a "Note from the AI" section or other meta-commentary in committed text.

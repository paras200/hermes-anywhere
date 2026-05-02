# Operations walkthrough

A complete tour of what you can do with this repo, in the order you'll do it.

> **Convention:** every operation has a `make <target>` shortcut that wraps a `scripts/<name>.sh` script. Run `make help` to list them.

## 1. Deploy

Already covered in [`README.md`](../README.md#quick-start) and [`terraform/README.md`](../terraform/README.md). One-liner reminder:

```bash
cd terraform/<provider>
cp terraform.tfvars.example terraform.tfvars   # fill in
terraform init && terraform apply
```

## 2. Post-deploy: smoke-test the VM

After `terraform apply` returns, SSH in and run the doctor:

```bash
ssh ... root@$(terraform output -raw public_ipv4)
cd /opt/hermes-anywhere
make doctor
```

Expected output: 7 checks, all passing within 90 seconds of boot. A first-boot failure is almost always one of:

- `OPENROUTER_API_KEY not set` → `.env` template substitution failed; re-check `terraform.tfvars`
- `dashboard not yet responding` → wait 30 more seconds; the dashboard rebuilds its UI on every start
- `OpenRouter key rejected (401)` → key was copied with whitespace; re-check `.env`

## 3. Stay on top of upstream releases

Hermes ships every 1–2 weeks. Three layers of awareness, in increasing automation:

### a) Check on demand

```bash
make check-update
```

Compares your pinned version against Docker Hub. Exits 0 if current, 1 if behind, prints the GitHub release-notes URL.

### b) Daily notification on the VM (Telegram or journald)

```bash
sudo make install-cron
```

Installs a systemd timer that runs `notify-update.sh` every day at 09:00 local time. If a new version is available **and you haven't already been notified about it**, it:

1. Logs to `journalctl -u hermes-update-check.service`
2. Sends a Telegram message (if `TELEGRAM_BOT_TOKEN` and `TELEGRAM_ALLOWED_USERS` are set in `.env`)

The notifier is idempotent — a marker file at `/var/lib/hermes-anywhere/last-notified-version` prevents daily re-spam about the same release.

### c) GitHub issue auto-opener

`ci/check-upstream.yml` (move into `.github/workflows/` to activate — see [`ci/README.md`](../ci/README.md)) runs daily on this repo's GitHub Actions and **opens an issue** when a new upstream version lands. Includes the release notes inline. Anyone who forks this repo gets it for free — no VM needed.

If you want to disable any single layer, that's fine — they're complementary, not dependent.

## 4. Apply an update

When you decide to update (whether prompted by the cron, the GitHub issue, or your own check):

```bash
# On your laptop, in the repo:
make update VERSION=v2026.5.7
git diff                                    # review the bump
git commit -am "Bump Hermes to v2026.5.7"
git push

# On the VM:
ssh ... root@<vm-ip>
cd /opt/hermes-anywhere
git pull
docker compose pull && docker compose up -d
make doctor                                 # confirm
```

`make update` rewrites the version in **7 places** atomically:

- `docker-compose.yml`
- `.env.example`
- `terraform/{hetzner,digitalocean,aws-lightsail,oracle,gcp}/variables.tf`

Use `--dry-run` (or `scripts/update.sh vX.Y.Z --dry-run`) to preview without writing.

## 5. Health checks

```bash
make doctor
```

Runs 7 checks:

| Check | What it verifies |
|---|---|
| Files | `docker-compose.yml` and `.env` exist |
| Docker | CLI on PATH, daemon running |
| Containers | `hermes-gateway` and `hermes-dashboard` both `running` (not `restarting`) |
| Dashboard | `http://127.0.0.1:9119/` returns 2xx |
| OpenRouter API key | `auth/key` endpoint returns 200 |
| Storage | `hermes-data/` present, disk usage <80% |
| Version | Pinned version matches Docker Hub latest |

Exit code is 0 if all pass, 1 otherwise — fine for use in a monitoring script.

## 6. Backup hermes-data/

`hermes-data/` is the agent's brain: skills, memory, auth tokens, Curator reports, conversation history. **Back it up** before any destructive operation (cloud migration, version downgrade, `terraform destroy`).

```bash
export BACKUP_PASSPHRASE="$(openssl rand -base64 32)"
# IMMEDIATELY paste BACKUP_PASSPHRASE into your password manager —
# without it the backup is unrecoverable.

make backup
# → backups/hermes-data.YYYY-MM-DD-HHMM.tgz.gpg
```

Backups are GPG-symmetric-encrypted with AES256. Excludes `logs/*.log` and `cache/` (regenerable).

Move off-host:

```bash
scp backups/hermes-data.*.tgz.gpg backup-host:/path/
# or
rclone copy backups/ remote:hermes-backups/
# or
aws s3 cp backups/hermes-data.*.tgz.gpg s3://your-bucket/
```

## 7. Restore hermes-data/

```bash
export BACKUP_PASSPHRASE="..."   # the same passphrase from backup time
make restore FILE=backups/hermes-data.2026-05-02-1430.tgz.gpg
```

Behavior:

1. Stops Hermes containers
2. Moves the current `hermes-data/` aside to `hermes-data.before-restore.<stamp>/` (preserved, not deleted — rollback if you need)
3. Decrypts + extracts the backup
4. Restarts containers

## 8. Migrate to a different cloud

Hermes' state is portable — `hermes-data/` is the only thing that matters. To move from cloud A to cloud B:

```bash
# 1. On A: back up
ssh A "cd /opt/hermes-anywhere && BACKUP_PASSPHRASE='...' make backup"
scp A:/opt/hermes-anywhere/backups/hermes-data.*.tgz.gpg .

# 2. Provision B (with the new provider's terraform module)
cd terraform/<new-provider>
terraform apply

# 3. On B: restore
scp hermes-data.*.tgz.gpg B:/opt/hermes-anywhere/backups/
ssh B "cd /opt/hermes-anywhere && BACKUP_PASSPHRASE='...' make restore FILE=backups/hermes-data.*.tgz.gpg"

# 4. Decommission A
cd terraform/<old-provider>
terraform destroy
```

Hermes does not require any explicit "migration mode" — it picks up its state on next start.

## 9. View logs

```bash
make logs
# or, more selective:
docker compose logs -f gateway --tail=100
docker compose logs -f dashboard --tail=100
```

Cron/timer logs:

```bash
sudo journalctl -u hermes-update-check.service --since '7 days ago'
```

## 10. Wipe and start over

```bash
docker compose down -v       # WARNING: -v wipes volumes (does NOT touch the bind mount hermes-data/)
rm -rf hermes-data           # this is the actual wipe
docker compose up -d
```

Or via Terraform (full VM destroy):

```bash
cd terraform/<provider>
terraform destroy
```

In both cases, **back up first** if there's anything in `hermes-data/` you care about.

## 11. Add a custom skill

See [`SKILLS.md`](SKILLS.md). Short version:

```bash
# Author locally
mkdir -p skills/my-skill/{references,scripts}
$EDITOR skills/my-skill/SKILL.md     # see skills/alpha-desk/ for the full pattern

# Deploy to the VM
scp -r skills/my-skill VM:/opt/hermes-anywhere/hermes-data/skills/

# Hermes picks it up on next conversation. The Curator grades it within 7 days.
```

## 12. Tune the model

See [`MODEL_SELECTION.md`](MODEL_SELECTION.md). Default is `openai/gpt-oss-120b:free`; switch via dashboard, Telegram (`/model …`), or by editing `hermes-data/.env`.

## 13. Tighten firewall before going permanent

The default `terraform.tfvars.example` files use `0.0.0.0/0` for SSH and dashboard access — convenient for first-run, **insecure for a permanent setup**. Before moving past day-one:

```hcl
# In terraform.tfvars
ssh_allowed_cidrs       = ["YOUR.HOME.IP/32"]
dashboard_allowed_cidrs = ["YOUR.HOME.IP/32"]
```

Then `terraform apply` to update the security group. Better still: front the dashboard with a Tailscale tailnet or a Cloudflare Tunnel, and close `9119` to the public internet entirely.

## What's next

- [`AGENTS.md`](../AGENTS.md) — execution guide for AI coding agents working on this repo
- [`SKILLS.md`](SKILLS.md) — how to author a skill
- [`MODEL_SELECTION.md`](MODEL_SELECTION.md) — model recommendations
- [`COSTS.md`](COSTS.md) — full hosting cost analysis
- [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) — common failure modes

# Troubleshooting

## `terraform apply` succeeded but dashboard not loading

The dashboard rebuilds its web UI on every container start — this takes 30–60 seconds. On a fresh VM, layered with Docker image pull, expect **90 seconds total** before the dashboard responds.

```bash
# SSH in and check
ssh ... "sudo docker ps"
# Both containers should show 'Up' status.

ssh ... "sudo docker compose -f /opt/hermes-anywhere/docker-compose.yml logs dashboard --tail=30"
# look for: 'dashboard listening on 0.0.0.0:9119'
```

## Containers in `Restarting` loop

99% of the time: missing or wrong `OPENROUTER_API_KEY`.

```bash
ssh ... "sudo cat /opt/hermes-anywhere/.env | grep -c OPENROUTER_API_KEY"
# expect: 1, with a non-empty value

ssh ... "sudo docker logs hermes-gateway --tail=50"
# look for: 'no LLM provider configured' or '401 unauthorized'
```

Fix: edit `/opt/hermes-anywhere/.env`, then `sudo docker compose -f /opt/hermes-anywhere/docker-compose.yml restart`.

## "OpenRouter not configured" in dashboard UI

**Cosmetic bug**, not a real problem. Dashboard displays env-var-sourced credentials as "not configured" even though the gateway uses them fine at runtime. Confirmed in upstream Hermes through at least v2026.4.30. Verify with a test message — if it works, ignore the UI label.

## Hitting OpenRouter rate limits

**Symptom:** gateway logs show `429 Too Many Requests` or `rate limit exceeded`.

**Cause:** without a $10 lifetime top-up on OpenRouter, free models are capped at 50 requests/day. An always-on agent burns through that within hours.

**Fix:** add $10 credit at https://openrouter.ai/credits. Same API key, no config change needed — limit jumps to 1,000/day automatically.

## Hetzner: `cx22 not available in <location>`

Some Hetzner locations don't carry every server type. Try `nbg1`, `fsn1`, `hel1` (EU) or `ash`, `hil` (US). Update `location` in `terraform.tfvars` and re-apply.

## Oracle: `Out of host capacity`

Oracle's Always-Free A1 capacity is region-dependent and often exhausted. Options:

1. Retry `terraform apply` every 30–60 minutes (free A1 capacity is volatile)
2. Switch region (`region = "uk-london-1"` or `"eu-frankfurt-1"` etc.)
3. Use a community tool like `oci-arm-host-capacity` to auto-retry

## Oracle: instance reclaimed after a week

Oracle reclaims Always-Free instances if the 95th-percentile CPU usage stays below 20% for 7 days. Hermes' cron + curator + dashboard normally produces enough activity to stay above this, but if it does happen:

```bash
# Re-create with the same Terraform state — same IP, fresh disk.
terraform apply -replace="oci_core_instance.hermes"
# Then restore hermes-data/ from your backup.
```

## GCP: `compute.googleapis.com has not been used in project ...`

Enable the Compute Engine API once per project:

```bash
gcloud services enable compute.googleapis.com --project=<your-project-id>
```

## SSH "permission denied (publickey)"

The username differs by cloud:

| Provider | Default user |
|---|---|
| Hetzner | `root` |
| DigitalOcean | `root` |
| AWS Lightsail | `admin` (Debian) or `ec2-user` (Amazon Linux) |
| Oracle (Ubuntu) | `ubuntu` |
| GCP | the `ssh_username` variable (default `hermes`) |

The `terraform output ssh_command` always shows the right one for that provider.

## Nothing works — start over

```bash
cd terraform/<provider>
terraform destroy
terraform apply
```

Wipes the VM and all Hermes state. **Back up `hermes-data/` first** if you have skills or memory you want to keep.

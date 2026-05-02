# Hermes Anywhere — Terraform

Five providers, one shared cloud-init bootstrap, identical resulting VM. Pick the cheapest cloud you can run on; switch with a `terraform destroy` + `terraform apply` in a different folder.

## Pick a cloud

| Provider | Best for | Cost / mo | Module |
|---|---|---|---|
| **Oracle Cloud Always Free** | Permanent $0 ARM VM | **$0** | [`oracle/`](oracle/) |
| **Hetzner Cloud** | Best paid price/perf | **€4.49 (~$5)** | [`hetzner/`](hetzner/) |
| **GCP (GCE)** | If already on Google Cloud | **~$13** | [`gcp/`](gcp/) |
| **AWS Lightsail** | If already on AWS | **$20** | [`aws-lightsail/`](aws-lightsail/) |
| **DigitalOcean** | Polished, mainstream | **$24** | [`digitalocean/`](digitalocean/) |

## How it works

Every module:

1. Creates a Linux VM (Debian 12 on x86 providers, Ubuntu 22.04 ARM on Oracle A1)
2. Renders [`../cloud-init/hermes.cloud-config.yaml.tpl`](../cloud-init/hermes.cloud-config.yaml.tpl) with your env vars
3. Hands cloud-init the rendered file as user_data
4. cloud-init: installs Docker → clones this repo → writes `.env` → starts compose via systemd
5. Opens ports `22` and `9119` in the cloud-native firewall

After `terraform apply`, the dashboard is up at the IP printed by `terraform output dashboard_url` in ~60–90 seconds (image pull + first-start dashboard build).

## Common workflow

```bash
cd terraform/<provider>
cp terraform.tfvars.example terraform.tfvars
# fill in credentials + secrets

terraform init
terraform plan
terraform apply

# … later
terraform destroy
```

## Multi-provider note

State is per-folder (`terraform/<provider>/terraform.tfstate`). You can have a Hermes running in two clouds at once if you want — they don't share state.

For sharing one Hermes brain between hosts, back up `hermes-data/` from the source VM and restore it on the destination. See [`../docs/MIGRATING.md`](../docs/MIGRATING.md).

## Security defaults

The `terraform.tfvars.example` files default to `0.0.0.0/0` for SSH and dashboard access — convenient for first-run, **insecure for production**. For a permanent setup, set:

```hcl
ssh_allowed_cidrs       = ["YOUR.HOME.IP.X/32"]
dashboard_allowed_cidrs = ["YOUR.HOME.IP.X/32"]
```

…or front the dashboard with a Tailscale / Cloudflare Tunnel and keep `9119` closed entirely.

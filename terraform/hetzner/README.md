# Hermes Anywhere — Hetzner Cloud

**Cost:** €4.49/mo (~$5) for `cx22` (2 vCPU, 4 GB, 40 GB NVMe). Best price/performance/reliability of the paid options.

## Prerequisites

1. Hetzner Cloud account → create a project at https://console.hetzner.cloud
2. API token: Project → Security → API Tokens → create with **Read & Write**
3. Local: `terraform`, `ssh-keygen` (an SSH key)

## Deploy

```bash
cd terraform/hetzner
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: hcloud_token, ssh_public_key, openrouter_api_key

terraform init
terraform apply
```

After ~60–90 seconds (cloud-init + image pull), the dashboard is reachable at the URL printed in `terraform output dashboard_url`.

## Destroy

```bash
terraform destroy
```

Wipes the VM and all Hermes state. Back up `hermes-data/` first if you care about it.

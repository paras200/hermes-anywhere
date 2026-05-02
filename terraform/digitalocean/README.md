# Hermes Anywhere — DigitalOcean

**Cost:** $24/mo for `s-2vcpu-4gb`. The polished, mainstream option.

## Prerequisites

1. DigitalOcean account
2. API token: https://cloud.digitalocean.com/account/api/tokens (Read & Write)

## Deploy

```bash
cd terraform/digitalocean
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

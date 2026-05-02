# Hermes Anywhere — Google Cloud (GCE)

**Cost:** ~$13/mo for `e2-small` (2 vCPU shared, 2 GB RAM) or ~$25/mo for `e2-medium` (2 vCPU, 4 GB).

> `e2-micro` is in the GCP free tier but only has 1 GB RAM — too small for Hermes.

## Prerequisites

1. GCP project (`gcloud projects create` or via console)
2. Enable Compute Engine API: `gcloud services enable compute.googleapis.com`
3. Local `gcloud` auth: `gcloud auth application-default login`
4. Billing enabled on the project (required even for low-cost VMs)

## Deploy

```bash
cd terraform/gcp
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

## Note on credits

If you're on a Google Cloud free trial credit, this works the same — the cost just comes off the credit balance. Once credits expire, the same `terraform apply` keeps running on a paid invoice; switch to Hetzner or Oracle Always Free if cost matters more than staying on GCP.

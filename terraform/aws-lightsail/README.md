# Hermes Anywhere — AWS Lightsail

**Cost:** $20/mo for `medium_3_0` (2 vCPU, 4 GB, 80 GB SSD, 4 TB transfer).

## Prerequisites

1. AWS account
2. Local AWS credentials: `aws configure` (uses `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`, or use AWS SSO)
3. The IAM user/role needs Lightsail permissions

## Deploy

```bash
cd terraform/aws-lightsail
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

## Note on cost

Lightsail's headline price is honest for steady-state, but watch out for: snapshot storage, static IP charges on stopped instances, and bandwidth overages above 4 TB. For a Hermes agent the bandwidth ceiling is rarely a concern.

# Hermes Anywhere — Oracle Cloud (Always Free, ARM Ampere A1)

**Cost:** $0/mo, permanent. Up to 4 OCPU + 24 GB RAM total across A1 instances.

> Hermes' Docker image is multi-arch (`arm64` supported), so the ARM-only Always-Free shape is fine.

## Caveats

- **Account approval** can be finicky — some signups get auto-rejected for fraud-flag reasons. Try a different payment method or contact support if denied.
- Oracle reclaims **idle** Always-Free instances if 95th-percentile CPU stays below 20% for 7 days. Hermes' gateway cron + curator + dashboard usually generates enough activity, but worth knowing.

## Prerequisites

1. Oracle Cloud account: https://signup.cloud.oracle.com (the **Always Free** tier signup)
2. Generate an API key:
   - Profile menu → **My Profile** → **API Keys** → **Add API Key** → "Generate API Key Pair"
   - Download the private key, save to `~/.oci/oci_api_key.pem` and `chmod 600`
   - Copy the fingerprint shown in the console
3. Find your availability domain: in Console → **Compute → Instances → Create**, the AD picker shows names like `AbCD:US-ASHBURN-AD-1`
4. Use your **tenancy OCID** as the `compartment_ocid` (root compartment) unless you've created sub-compartments

## Deploy

```bash
cd terraform/oracle
cp terraform.tfvars.example terraform.tfvars
# fill in tenancy_ocid, user_ocid, fingerprint, private_key_path, compartment_ocid, availability_domain, ssh_public_key, openrouter_api_key

terraform init
terraform apply
```

If you hit `Out of host capacity` on apply, that's Oracle's region being out of free A1 capacity at that moment. Retry with `terraform apply` every 30–60 minutes, or pick a different region.

# Terraform — BDI Infrastructure

Infrastructure for bdi-infrastructure GCP project.

## Modules
- `cloudflare/` — DNS and DDoS protection
- `vercel/` — Vercel project configuration
- `supabase/` — Supabase PostgreSQL databases

## Init & Deploy
```bash
terraform init
terraform plan
terraform apply
```

## State
Terraform state is managed remotely (GCS backend).

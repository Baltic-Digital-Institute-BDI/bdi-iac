# bdi-iac — BDI Infrastructure as Code

Monorepo for BDI infrastructure automation, including Terraform IaC, n8n workflow exports, database schemas, edge functions, and security policies.

## Structure
- `terraform/` — Terraform modules (Cloudflare DNS, Vercel config, Supabase)
- `n8n/workflows/` — Exported n8n workflows (read-only backup, LEGACY and BDI-INFRA categories)
- `database/` — Database schemas and migrations
- `edge-functions/` — Deno edge function code
- `security/` — Security policies and RBAC configs

## Usage
See individual READMEs in each subdirectory.

## Support
Contact: Krzysztof Rek (BDI C-level)

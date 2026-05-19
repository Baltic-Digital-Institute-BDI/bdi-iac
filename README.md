# bdi-iac — BDI Infrastructure as Code

Monorepo for BDI infrastructure automation, including Terraform IaC, n8n workflow exports, database schemas, edge functions, and security policies.

## Structure

| Path | Purpose |
|---|---|
| `terraform/` | Terraform modules (Cloudflare DNS · Vercel config · Supabase) |
| `n8n/workflows/` | Exported n8n workflows (read-only backup · LEGACY + BDI-INFRA categories) |
| `L1_INFRASTRUCTURE/supabase/migrations/` | Supabase SQL migrations (date-prefix · numbered · canonical) |
| `L1_INFRASTRUCTURE/supabase/edge-functions/` | Deno edge function code |
| `L0_GOVERNANCE/` | Governance docs · ADRs · access policies |
| `docs/` | Architecture + operations documentation |

## Active Streams · PROD status

### Stream 5 · Cross-Laptop Message Envelope — 🟢 LIVE 2026-05-19

**Authority**: D-STU-081 + D-STU-088 + D-STU-089 + STOP-4 KR signoff
**Project**: `bdi-prod` (`vpbbguexygbqovsjfsab`)
**Schema**: `control_plane.*` (7 tables · 17 indexes · 9 RLS policies · 1 trigger)
**Applied migrations** (`L1_INFRASTRUCTURE/supabase/migrations/`):
- `20260519_001_stream_05_cp_messages_envelope_PROD.sql` (table envelope v1 · 18 fields)
- `20260519_002_stream_05_rls_baseline.sql` (RLS + SEC-DOMAIN-BLOCK trigger)
- `20260519_001_stream_05_cp_messages_envelope_ROLLBACK.sql` (safety rollback path)

**Detailed status**: see [`L1_INFRASTRUCTURE/supabase/migrations/README_stream_05.md`](L1_INFRASTRUCTURE/supabase/migrations/README_stream_05.md).

**Unblock cascade post-LIVE**:
- Track 1 BBC v1.0 deploy · cp_messages PROD dependency MET
- Track 3 Slack integration n8n workflows · path clear
- Pilot F10/F11 (KR + Olga) · interim mode terminate · daily envelope emission ready

## Usage

See individual READMEs in each subdirectory.

## Branch policy (per ADR-OPS-001 D-OPS-13 Build immutability)

- `main` = canonical · protected · NIE direct push
- Feature branches → PR → KR review (STOP-4 dla PROD changes) → merge
- Builds = versioned ZIPs (append-only · NIE overwrite)

## Support

Contact: Krzysztof Rek (BDI C-level) · krzysztof@baltic-digital.org

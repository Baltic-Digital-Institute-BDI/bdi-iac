# Supabase Migrations · Canonical SSOT

**SSOT** dla Supabase PROD schema migrations w **bdi-prod** project (`vpbbguexygbqovsjfsab`).
Per BDI-GOV-002 v3.1 §2 (Pattern E · machine-consumed) + Infrastructure Master Map v1.5 D8 (`bdi-iac` monorepo).

## Naming convention

```
YYYYMMDD_NNN_short_description[_PROD|_ROLLBACK].sql
```

- `YYYYMMDD` — migration date (Europe/Warsaw)
- `NNN` — 3-digit sequence within the date (001, 002, ...)
- `_PROD` suffix optional for forward migrations applied to PROD
- `_ROLLBACK` suffix mandatory for companion rollback scripts

## Migration timeline

| Date | Seq | Migration | Owner | Status | Project |
|---|---|---|---|---|---|
| 2026-04-09 | 001 | `fix_is_admin_add_super_admin` | HIGH-014 | APPLIED | bdi-prod |
| 2026-04-09 | 002 | `lab_access_domains` | HIGH-014 | APPLIED | bdi-prod |
| 2026-04-09 | 003 | `lab_user_domain_access` | HIGH-014 | APPLIED | bdi-prod |
| 2026-04-09 | 004 | `seed_users_adam_olga` | HIGH-014 | APPLIED | bdi-prod |
| 2026-04-09 | 005 | `w805_plc_cleanup` | HIGH-014 | APPLIED | bdi-prod |
| **2026-05-19** | **001** | **`stream_05_cp_messages_envelope_PROD`** | **STU-S5-5** | **APPLIED 2026-05-18** | **bdi-prod** |
| **2026-05-19** | **001** | **`stream_05_cp_messages_envelope_ROLLBACK`** | **STU-S5-5** | **STANDBY** | **bdi-prod** |
| **2026-05-19** | **002** | **`stream_05_rls_baseline`** | **STU-S5-5** | **APPLIED 2026-05-18** | **bdi-prod** |

## Stream 5 cross-laptop message envelope · 2026-05-19 batch

Migration batch authorized by **kr_prime STOP-4** ratification (Variant B Amended) per **D-STU-081** + **D-STU-088** (PI v4.0 sekcja 10).

### Forward migrations (2)

| File | Bytes | Purpose |
|---|---|---|
| `20260519_001_stream_05_cp_messages_envelope_PROD.sql` | 10,695 | Schema `control_plane` + 7 tables (cp_messages · cp_dlq · cp_agent_state · cp_identity_cards · cp_session_log · cp_routing_rules · cp_run_metrics) · 12-field envelope v1.6 · composite index per gate C3 finding |
| `20260519_002_stream_05_rls_baseline.sql` | 6,779 | Row Level Security baseline · service_role full access · authenticated read own-workspace · anon DENY · SEC-DOMAIN-BLOCK enforcement |

### Rollback (1 · companion to PROD)

| File | Bytes | Purpose |
|---|---|---|
| `20260519_001_stream_05_cp_messages_envelope_ROLLBACK.sql` | 3,859 | DROP all 7 cp_* tables + DROP schema control_plane CASCADE · destructive · KR signoff required pre-execution |

## Applied verification (post-PROD LIVE 2026-05-18)

```sql
-- Verify schema + tables present
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'control_plane';
SELECT table_name FROM information_schema.tables WHERE table_schema = 'control_plane';
-- Expected: 7 tables (cp_messages, cp_dlq, cp_agent_state, cp_identity_cards,
--                     cp_session_log, cp_routing_rules, cp_run_metrics)
```

Source: replicate TEST `adsdaehvvnwknjushshn` migration `20260510185441` with 2 improvements:
1. Composite index `(target_workspace, created_at DESC)` added (gate C3 finding)
2. Redundant `cp_messages_correlation_idx` OMITTED (duplicate of PK)

## Authority chain

- **D-STU-081**: Stream 5 envelope v1.6 spec ratified
- **D-STU-088**: PI v4.0 sekcja 10 cp_messages emission examples
- **D-STU-092**: PROD LIVE confirmation (2026-05-18 EOD)
- **D-STU-102**: IaC canonicalization (this commit · 2026-05-19)
- **STU-AUDIT-GOV-002-001**: GOV-002 compliance audit identified B.4 SQL migrations violation

## Apply procedure (PROD)

```bash
# Pre-flight
psql "$PROD_DATABASE_URL" -c "SELECT current_database(), version();"

# Apply forward (in BEGIN/COMMIT transaction)
psql "$PROD_DATABASE_URL" -f 20260519_001_stream_05_cp_messages_envelope_PROD.sql
psql "$PROD_DATABASE_URL" -f 20260519_002_stream_05_rls_baseline.sql

# Verify
psql "$PROD_DATABASE_URL" -c "SELECT count(*) FROM control_plane.cp_messages;"
```

## Rollback procedure (KR signoff required)

```bash
# DESTRUCTIVE · all cp_* data lost
psql "$PROD_DATABASE_URL" -f 20260519_001_stream_05_cp_messages_envelope_ROLLBACK.sql
```

## Companion documents

- `W8.05_cleanup_plan.md` — HIGH-014 plc_* cleanup plan (W8.05 series)
- Stream 5 OR reports: `BDI-STUDIO/_OUTPUTS/sub-agents/sprint-2/STU-S5-5/*.md` (Drive · agent ORs Pattern A · NOT canonicalized to bdi-iac · per GOV-002 §2 row "Audits/Reviews")

## Change-log

| Date | Migrations added | Author |
|---|---|---|
| 2026-04-09 | 005 (HIGH-014 W8.05 cleanup batch) | HIGH-014 |
| 2026-05-19 | Stream 5 PROD + RLS baseline + ROLLBACK (3 files) | STU-IAC-MIGRATE (CCS · sprint-2 day-2) |

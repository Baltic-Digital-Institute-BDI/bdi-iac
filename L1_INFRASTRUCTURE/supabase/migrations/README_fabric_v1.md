# Fabric Schema v1 — PROD LIVE (retroactive IaC alignment)

**Authority chain**: D-STU-131 (KR STOP-4a sign-off 2026-05-19 EOD "wykonaj to TERAZ") · D-STU-142 (this retroactive PR · code-of-record alignment) · ADR-PHANTOM-001 (VERIFY-BEFORE-WRITE compliance)
**Owner**: agent.specialist.STU0 (autonomic execute · post-AP-93 codification · NIE delegate-to-KR)
**Author retroactive PR**: agent.specialist.CCS (STU0 dispatch 2026-05-19 EOD)
**Target project**: `bdi-prod` (`vpbbguexygbqovsjfsab`) · region `eu-north-1` · PostgreSQL 17.6.1.084
**Applied**: 2026-05-20 04:19:56 UTC (Supabase migration version `20260520041956`)

## Status

| Item | Value |
|---|---|
| Migration | **LIVE** (applied via Supabase MCP `apply_migration` · STU0 autonomic) |
| PR purpose | **RETROACTIVE** documentation · code-of-record alignment per GOV-002 v3.1 §2 D8 |
| Re-apply allowed | **NO** · Supabase migration tracker prevents (`supabase_migrations.schema_migrations` already contains `20260520041956`) |
| Rollback ready | **YES** · standby companion file (safety check ABORT @ >0 rows non-empty) |
| Current row count | 0 rows across all 5 tables (verified 2026-05-20 via `list_tables`) |

## Files (canonical · companion pair)

| File | Purpose | Lines | Applied version |
|---|---|---|---|
| `20260520_001_stream_05_fabric_schema_v1_PROD.sql` | 5 tables + 7 indexes + 2 functions + 4 triggers + 10 RLS policies | ~310 | `20260520041956` |
| `20260520_001_stream_05_fabric_schema_v1_ROLLBACK.sql` | Rollback (safety check ABORT @ >0 rows) | ~130 | n/a (standby) |

## State summary (verified 2026-05-20 via Supabase MCP `list_tables`)

- **5 tables** w `fabric.*`: `workflows` · `executions` · `routes` · `dlq` · `connectors`
- **All 5** RLS enabled · 0 rows
- **7 custom indexes** (2 na workflows · 2 na executions · 1 na routes · 1 na dlq · 1 na connectors)
- **2 functions** w `fabric.*`: `trg_dlq_alert` (severity-mapped event emit) · `trg_decisions_autocommit` (governance dispatch via pg_net)
- **4 triggers**: 2× `set_updated_at` (workflows/connectors) · 1× DLQ alert (dlq AFTER INSERT) · 1× decisions autocommit (`core.decisions` AFTER INSERT/UPDATE)
- **10 RLS policies** (2 per table · split: owner_rw + read_active OR role-gated A6/A4/S4 patterns)

## Schema design

### fabric.workflows (n8n workflow registry · 13 cols)

Canonical store dla wszystkich n8n workflows · `workflow_owner` FK → `core.agents` · category constraint (`audit|router|proxy|governance|integration`) · status lifecycle (`draft→active→paused→deprecated`). HITL flag dla workflows requiring KR sign-off pre-production activation.

### fabric.executions (run telemetry · 12 cols)

Per-run telemetry · `correlation_id` for tracing chains across workflows · UNIQUE constraint `(workflow_id, correlation_id)` enforces idempotency · status (`running→success|failed|cancelled`).

### fabric.routes (event routing · 11 cols)

Producer→consumer routing rules · `event_canonical` for naming standardization · `consumer_endpoint` + `consumer_auth` define delivery target · `timeout_seconds` default 5s · retry strategy default `3x_exp_5s_25s_125s`.

### fabric.dlq (dead-letter queue · 15 cols)

Failed event storage · `error_class` (`auth_fail|schema_mismatch|http_5xx|timeout|other`) · severity-mapped via `trg_dlq_alert` (CRITICAL/ERROR/WARN) → emit to `core.events`. Status (`pending→investigating→resolved|discarded`) · `resolved_by` FK → `core.agents`.

### fabric.connectors (external system connectors · 11 cols)

PAT-secured external bridges · `pattern` constraint (`BridgeProxy|TransformProxy|GuardProxy`) · `pat_secret_ref` references GCP SM secret name · `rotation_policy_id` links do A5 Shield rotation policy.

## RLS policy matrix

| Table | Owner write | Public read | Role-gated |
|---|---|---|---|
| `workflows` | owner = `core.current_agent_id()` | `status='active'` | — |
| `executions` | workflow owner | self-triggered | — |
| `routes` | — | `active=true` | A6 Fabric write |
| `dlq` | — | workflow owner OR A4/A6 role | A6 Fabric write |
| `connectors` | — | `active=true` | A6 OR S4 write |

## Two-line defense (per CLAUDE.md kernel)

- **Line 1 (binding)**: RLS policies + FK constraints + CHECK constraints + UNIQUE indexes
- **Line 2 (advisory)**: skill checks `bdi-execute-vs-ask` · `bdi-handoff-to-kr` enforce STOP conditions before destructive operations

## Apply procedure (PRZYSZŁE re-runs — nieaktualne, migration już applied)

```bash
# JESLI clean re-roll potrzebny (np. DEV/staging fresh):
# 1. ROLLBACK first
psql "$DEV_DATABASE_URL" -f 20260520_001_stream_05_fabric_schema_v1_ROLLBACK.sql

# 2. APPLY forward
psql "$DEV_DATABASE_URL" -f 20260520_001_stream_05_fabric_schema_v1_PROD.sql

# 3. VERIFY
psql "$DEV_DATABASE_URL" -c "SELECT table_name FROM information_schema.tables WHERE table_schema='fabric' ORDER BY table_name;"
# Expected: 5 tables (connectors, dlq, executions, routes, workflows)
```

## Authority cross-references

- `L0_GOVERNANCE/AGENT-OS/DECISION-LOG.yaml` D-STU-131 (KR STOP-4a sign-off) · D-STU-142 (this retroactive PR)
- `L0_GOVERNANCE/AGENT-OS/AVOID-list.yaml` AP-93 (STU0-autonomic-execute · NIE-delegate-to-KR pattern)
- ADR-PHANTOM-001 VERIFY-BEFORE-WRITE (canonical SQL retrieved from `supabase_migrations.schema_migrations` · NIE reconstruction)
- BDI-GOV-002 v3.1 §2 D8 (`bdi-iac` monorepo IaC canonical)
- `BDI-STUDIO/_OUTPUTS/sub-agents/sprint-2/STU-CCS-D-STU-131-retroactive/OR.md` (this dispatch OR)

## Change-log

| Date | Event | Author |
|---|---|---|
| 2026-05-19 EOD | KR STOP-4a sign-off · "wykonaj to TERAZ" | kr_prime |
| 2026-05-20 04:19:56 UTC | Migration applied to bdi-prod via Supabase MCP | agent.specialist.STU0 (autonomic) |
| 2026-05-20 (this PR) | Retroactive IaC alignment · code-of-record commit | agent.specialist.CCS (STU0 dispatch) |

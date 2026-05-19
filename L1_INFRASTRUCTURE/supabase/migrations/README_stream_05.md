# Stream 5 Cross-Laptop Message Envelope — PROD LIVE

**Authority chain**: D-STU-081 (W25-Q3) + D-STU-088 (W25-Q10 Track 2) + D-STU-089 (Variant B ratify) + STOP-4 KR signoff 2026-05-19
**Owner**: agent.specialist.STU0 + agent.specialist.STU-S5-5 (CCS ephemeral · 9-criterion gate audit author)
**Target project**: `bdi-prod` (`vpbbguexygbqovsjfsab`) · region `eu-north-1` · PostgreSQL 17.6.1.084
**Applied**: 2026-05-19 02:38:23 UTC

## Files (canonical · NIE duplicate w innych ścieżkach)

| File | Purpose | Lines | Applied version |
|---|---|---|---|
| `20260519_001_stream_05_cp_messages_envelope_PROD.sql` | 7 tables + 17 indexes + 1 SELECT policy | 195 | `20260519023646` |
| `20260519_001_stream_05_cp_messages_envelope_ROLLBACK.sql` | Rollback (safety check ABORT @ >10 non-smoke rows) | 80 | n/a |
| `20260519_002_stream_05_rls_baseline.sql` | 8 service_role policies + SEC-DOMAIN-BLOCK trigger | 165 | `20260519023723` |

## State summary (verified 2026-05-19 via Supabase MCP `list_migrations`)

- **7 tables** w `control_plane.*`: `cp_messages` · `cp_outbox` · `cp_inbox` · `cp_dlq` · `cp_acks` · `cp_correlation_groups` · `cp_agent_state`
- **17 indexes** (7 na `cp_messages` · 2 na `cp_outbox` · 3 na `cp_inbox` · 1 na `cp_dlq` · 1 na `cp_acks` · 3 na `cp_agent_state`)
- **9 RLS policies** (1 domain isolation SELECT · 8 service_role: 2 cp_messages + 6 ALL na pozostałych tabelach)
- **1 trigger function** `enforce_domain_boundary` (SECURITY DEFINER · D-STU-075 one-way matrix)
- **1 trigger** `cp_messages_domain_boundary_check` (BEFORE INSERT · BDI-GOV→ENE/PE → cp_dlq + RAISE)

## Envelope v1 schema (18 fields)

Identity (3): `message_id` · `run_id` · `correlation_id`
Routing (4): `source_workspace` · `target_workspace` · `domain` · `device_id`
Actor (2): `actor_type` (HUM/CCA/CCS/N8N/OTH) · `actor_id`
Classification (2): `sensitivity_level` (L0_PUBLIC..L4_RESTRICTED · 5 levels) · `message_type`
Payload (2): `payload` (jsonb) · `artifact_uri`
Lifecycle (5): `status` (pending/sent/ack/fail/dlq/archived · 6 values) · `ack_deadline` · `retention_class` (default '7y') · `created_at` · `acked_at`

## Smoke envelope (post-LIVE confirmation)

- `message_id`: `627f4c73-ebce-40de-b7b5-a27deb8a4167`
- `message_type`: `OR_SUBMISSION`
- `actor_id`: `agent.specialist.STU-S5-5`
- `status`: `pending`
- `created_at`: 2026-05-19 02:38:23 UTC

## Improvements vs TEST baseline (baked into PROD per 9-criterion gate)

- Redundant `cp_messages_correlation_idx` OMITTED · new composite `cp_messages_target_ws_created_idx` ADDED (gate C3)
- 9 RLS policies vs TEST 1 (gate C2) · DELETE on cp_messages implicit deny (append-only enforced)
- SEC-DOMAIN-BLOCK trigger ENFORCED (BDI-GOV → ENE/PE auto-DLQ + RAISE per D-STU-075) · gate C6 PARTIAL FAIL closed

## Re-run safety (idempotency)

Files use `CREATE SCHEMA IF NOT EXISTS` for `control_plane`. Tables/indexes/policies/trigger are **NOT** wrapped in IF NOT EXISTS — re-running on populated PROD will raise `relation already exists`. This is by design (append-only DDL · Supabase migration tracker prevents re-run via `supabase_migrations.schema_migrations`). For DEV/staging clean re-apply, use `ROLLBACK` first.

## Authority cross-references

- `BDI-STUDIO/_OUTPUTS/STU-S5-5_9-criterion-gate-OR.md` (TEST→PROD audit)
- `L0_GOVERNANCE/AGENT-OS/DECISION-LOG.yaml` D-STU-081..092
- PROJECT INSTRUCTIONS v4.1.6 sekcja 10 (cp_messages envelope spec) · sekcja 10.4 (PROD LIVE status)

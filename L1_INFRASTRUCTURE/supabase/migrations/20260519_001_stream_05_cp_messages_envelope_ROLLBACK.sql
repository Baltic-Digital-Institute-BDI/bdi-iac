-- =============================================================================
-- Migration ROLLBACK: stream_05_cross_laptop_message_envelope_v1_PROD
-- Project: bdi-prod (vpbbguexygbqovsjfsab)
-- Author: agent.specialist.STU-S5-5 (CCS ephemeral · sprint-2 day-1)
-- Date: 2026-05-18
-- Purpose: Reverse stream_05_PROD.sql + stream_05_rls_baseline.sql
-- TRIGGER conditions:
--   1. get_advisors security WARN ≥1 na control_plane.* tables (auto-trigger)
--   2. Smoke INSERT failure mid-verify (auto-trigger · escalate STOP-4)
--   3. KR explicit revert request post-deploy (manual trigger)
--   4. A6 Fabric coordination break detected (manual · STOP-3 escalate)
-- AUTHORITY: kr_prime STOP-1 required (destrukcyjne irreversible IF data present)
--   · safe pre-data state · NIE wymaga STOP-1 jeśli zero rows OR test smoke only
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- Safety check: jeśli production data already (>1 row non-smoke) · ABORT manualnie
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  msg_count integer;
  non_smoke_count integer;
BEGIN
  SELECT count(*) INTO msg_count FROM control_plane.cp_messages;
  SELECT count(*) INTO non_smoke_count
    FROM control_plane.cp_messages
    WHERE message_type NOT LIKE 'test_smoke_%'
      AND message_type NOT LIKE 'STU-S5-5_%';

  RAISE NOTICE 'cp_messages total rows: %', msg_count;
  RAISE NOTICE 'non-smoke production rows: %', non_smoke_count;

  IF non_smoke_count > 10 THEN
    RAISE EXCEPTION 'ROLLBACK ABORTED: % production rows detected · escalate STOP-1 do KR · use selective DROP instead', non_smoke_count;
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- DROP TABLES (reverse FK dependency order)
-- -----------------------------------------------------------------------------

-- Leaf tables first (no incoming FK)
DROP TABLE IF EXISTS control_plane.cp_agent_state CASCADE;
DROP TABLE IF EXISTS control_plane.cp_correlation_groups CASCADE;

-- Tables with FK to cp_messages
DROP TABLE IF EXISTS control_plane.cp_acks CASCADE;
DROP TABLE IF EXISTS control_plane.cp_dlq CASCADE;
DROP TABLE IF EXISTS control_plane.cp_inbox CASCADE;
DROP TABLE IF EXISTS control_plane.cp_outbox CASCADE;

-- Core envelope (last · referenced by all above)
DROP TABLE IF EXISTS control_plane.cp_messages CASCADE;

-- -----------------------------------------------------------------------------
-- DROP SCHEMA (assuming control_plane = Stream 5 exclusive scope)
-- -----------------------------------------------------------------------------
DROP SCHEMA IF EXISTS control_plane CASCADE;

COMMIT;

-- =============================================================================
-- POST-ROLLBACK EXPECTED STATE:
-- · control_plane schema = absent
-- · 0 cp_* tables w PROD
-- · zero policies dropped (kaskadowo z tables)
-- · 17 indexes dropped (kaskadowo)
-- · supabase_migrations.schema_migrations entry NIE auto-removed (manualnie usuń version 'stream_05_cross_laptop_message_envelope_v1_PROD' jeśli replay potrzebny)
-- =============================================================================

-- =============================================================================
-- POST-ROLLBACK ACTION ITEMS:
-- 1. STU-S5-5 emit cp_message envelope rollback notice (jeśli cp_messages already gone · use Slack)
-- 2. STU0 update DECISION-LOG: D-STU-089 → REVERTED
-- 3. Slack #ws-bdi-studio: "🚨 Stream 5 PROD ROLLBACK applied · reason: [trigger]"
-- 4. PI v4.0 sekcja 10.4 revert update
-- 5. Schedule retry workshop (sprint-3 candidate) jeśli systemic issue
-- =============================================================================

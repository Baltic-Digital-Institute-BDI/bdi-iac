-- =============================================================================
-- Migration ROLLBACK: stream_05_fabric_schema_v1_PROD
-- Project: bdi-prod (vpbbguexygbqovsjfsab)
-- Author: agent.specialist.STU0 (autonomic execute · D-STU-131 retroactive PR)
-- Companion to: 20260520_001_stream_05_fabric_schema_v1_PROD.sql
-- Purpose: Reverse fabric.* schema migration (5 tables + 2 functions + 4 triggers + 10 RLS policies)
--
-- TRIGGER conditions:
--   1. get_advisors security WARN >=1 na fabric.* tables (auto-trigger A5 Shield review)
--   2. n8n integration failure post-deploy (manual · STOP-3 escalate)
--   3. KR explicit revert request (manual trigger)
--   4. A6 Fabric coordination break detected (manual · STOP-3 escalate)
--
-- AUTHORITY: kr_prime STOP-1 required jesli production data present (>0 rows)
--   safe pre-data state · NIE wymaga STOP-1 jesli zero rows (current state · all 5 tables empty)
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- Safety check: ABORT jesli fabric.* contains non-empty data
-- -----------------------------------------------------------------------------
DO $safety$
DECLARE
  v_workflows_count integer;
  v_executions_count integer;
  v_routes_count integer;
  v_dlq_count integer;
  v_connectors_count integer;
  v_total integer;
BEGIN
  SELECT count(*) INTO v_workflows_count FROM fabric.workflows;
  SELECT count(*) INTO v_executions_count FROM fabric.executions;
  SELECT count(*) INTO v_routes_count FROM fabric.routes;
  SELECT count(*) INTO v_dlq_count FROM fabric.dlq;
  SELECT count(*) INTO v_connectors_count FROM fabric.connectors;
  v_total := v_workflows_count + v_executions_count + v_routes_count + v_dlq_count + v_connectors_count;

  IF v_total > 0 THEN
    RAISE EXCEPTION 'ROLLBACK ABORT · fabric.* contains % rows (workflows=%, executions=%, routes=%, dlq=%, connectors=%) · KR STOP-1 sign-off required before destructive rollback',
      v_total, v_workflows_count, v_executions_count, v_routes_count, v_dlq_count, v_connectors_count;
  END IF;

  RAISE NOTICE 'Safety check PASS · fabric.* empty · rollback proceeding';
END $safety$;

-- -----------------------------------------------------------------------------
-- STEP 1: DROP triggers (in reverse order · dependents first)
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_decisions_autocommit ON core.decisions;
DROP TRIGGER IF EXISTS trg_fabric_dlq_alert ON fabric.dlq;
DROP TRIGGER IF EXISTS trg_fabric_connectors_updated ON fabric.connectors;
DROP TRIGGER IF EXISTS trg_fabric_workflows_updated ON fabric.workflows;

-- -----------------------------------------------------------------------------
-- STEP 2: DROP RLS policies (10 total)
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS fabric_connectors_read_active ON fabric.connectors;
DROP POLICY IF EXISTS fabric_connectors_a6_s4_write ON fabric.connectors;
DROP POLICY IF EXISTS fabric_dlq_read_workflow_owner ON fabric.dlq;
DROP POLICY IF EXISTS fabric_dlq_a6_write ON fabric.dlq;
DROP POLICY IF EXISTS fabric_routes_read_active ON fabric.routes;
DROP POLICY IF EXISTS fabric_routes_a6_write ON fabric.routes;
DROP POLICY IF EXISTS fabric_executions_read_self_triggered ON fabric.executions;
DROP POLICY IF EXISTS fabric_executions_owner_rw ON fabric.executions;
DROP POLICY IF EXISTS fabric_workflows_read_active ON fabric.workflows;
DROP POLICY IF EXISTS fabric_workflows_owner_rw ON fabric.workflows;

-- -----------------------------------------------------------------------------
-- STEP 3: DROP indexes (7 custom · PK indexes drop with tables)
-- -----------------------------------------------------------------------------
DROP INDEX IF EXISTS fabric.idx_fabric_connectors_active;
DROP INDEX IF EXISTS fabric.idx_fabric_dlq_status;
DROP INDEX IF EXISTS fabric.idx_fabric_routes_event;
DROP INDEX IF EXISTS fabric.idx_fabric_executions_status;
DROP INDEX IF EXISTS fabric.idx_fabric_executions_workflow;
DROP INDEX IF EXISTS fabric.idx_fabric_workflows_status;
DROP INDEX IF EXISTS fabric.idx_fabric_workflows_owner;

-- -----------------------------------------------------------------------------
-- STEP 4: DROP tables (reverse FK order · dependents first)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS fabric.connectors CASCADE;
DROP TABLE IF EXISTS fabric.dlq CASCADE;
DROP TABLE IF EXISTS fabric.routes CASCADE;
DROP TABLE IF EXISTS fabric.executions CASCADE;
DROP TABLE IF EXISTS fabric.workflows CASCADE;

-- -----------------------------------------------------------------------------
-- STEP 5: DROP functions
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS fabric.trg_decisions_autocommit() CASCADE;
DROP FUNCTION IF EXISTS fabric.trg_dlq_alert() CASCADE;

-- NOTE: core.current_agent_role() NIE droppujemy · moze byc uzywana przez inne schemas

-- -----------------------------------------------------------------------------
-- STEP 6: optional · DROP fabric schema (commented · uncomment jesli no other objects)
-- -----------------------------------------------------------------------------
-- DROP SCHEMA IF EXISTS fabric;
-- NOTE: schema created independently via s3_sprint1_phase1c_step1_create_8_schemas migration
-- DO NOT drop unless explicit KR STOP-1 sign-off · cascade could break other components

-- -----------------------------------------------------------------------------
-- Verification post-rollback
-- -----------------------------------------------------------------------------
DO $verify$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count
    FROM information_schema.tables
    WHERE table_schema = 'fabric'
      AND table_name IN ('workflows','executions','routes','dlq','connectors');
  IF v_count > 0 THEN
    RAISE EXCEPTION 'ROLLBACK INCOMPLETE · % fabric.* tables still present', v_count;
  END IF;
  RAISE NOTICE 'Rollback verification PASS · 0 fabric.* tables remaining';
END $verify$;

COMMIT;

-- =============================================================================
-- END OF ROLLBACK · destrukcyjne · status post-execute: fabric.* schema empty
-- =============================================================================

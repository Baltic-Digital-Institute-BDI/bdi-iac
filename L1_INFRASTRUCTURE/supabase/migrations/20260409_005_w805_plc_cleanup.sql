-- ============================================================================
-- W8.05 Migration Cleanup — plc_* table consolidation
-- HIGH-014 Everything-as-Code
-- Date: 2026-04-09
-- ============================================================================
-- INVENTORY (19 plc_* tables):
--   15 empty → DROP
--    1 plc_audit_log (93 rows) → migrate into lab_audit_log, DROP
--    1 plc_auth_matrix (36 rows) → RENAME to lab_auth_matrix (active RBAC data)
--    1 plc_feature_flags (8 rows) → RENAME to lab_feature_flags (active flags)
--    1 plc_domain_registry (11 rows) → DROP (superseded by lab_access_domains W8.02)
-- ============================================================================

BEGIN;

-- ── STEP 1: DROP 15 empty tables ────────────────────────────────────────────
DROP TABLE IF EXISTS lab_console.plc_agent_logs CASCADE;
DROP TABLE IF EXISTS lab_console.plc_agent_registry CASCADE;
DROP TABLE IF EXISTS lab_console.plc_change_log CASCADE;
DROP TABLE IF EXISTS lab_console.plc_compliance_refs CASCADE;
DROP TABLE IF EXISTS lab_console.plc_decision_log CASCADE;
DROP TABLE IF EXISTS lab_console.plc_design_artifacts CASCADE;
DROP TABLE IF EXISTS lab_console.plc_discovery_artifacts CASCADE;
DROP TABLE IF EXISTS lab_console.plc_dora_metrics CASCADE;
DROP TABLE IF EXISTS lab_console.plc_events CASCADE;
DROP TABLE IF EXISTS lab_console.plc_gate_reviews CASCADE;
DROP TABLE IF EXISTS lab_console.plc_products CASCADE;
DROP TABLE IF EXISTS lab_console.plc_release_train CASCADE;
DROP TABLE IF EXISTS lab_console.plc_test_runs CASCADE;
DROP TABLE IF EXISTS lab_console.plc_test_scenarios CASCADE;
DROP TABLE IF EXISTS lab_console.plc_version_registry CASCADE;

-- ── STEP 2: Migrate plc_audit_log → lab_audit_log ───────────────────────────
-- Add missing 'reason' column to lab_audit_log (exists in plc_ version)
ALTER TABLE lab_console.lab_audit_log
  ADD COLUMN IF NOT EXISTS reason text;

-- Copy 93 rows, skip duplicates by id
INSERT INTO lab_console.lab_audit_log (id, entity_type, entity_id, action, old_values, new_values, changed_by, created_at, reason)
SELECT id, entity_type, entity_id, action, old_values, new_values, changed_by, created_at, reason
FROM lab_console.plc_audit_log
ON CONFLICT (id) DO NOTHING;

-- Drop source
DROP TABLE lab_console.plc_audit_log CASCADE;

-- ── STEP 3: Rename active plc_ tables to lab_ namespace ─────────────────────
ALTER TABLE lab_console.plc_auth_matrix RENAME TO lab_auth_matrix;
ALTER TABLE lab_console.plc_feature_flags RENAME TO lab_feature_flags;

-- ── STEP 4: Drop plc_domain_registry (superseded by lab_access_domains) ─────
-- All ssot_table references point to plc_* tables we just dropped
DROP TABLE lab_console.plc_domain_registry CASCADE;

COMMIT;

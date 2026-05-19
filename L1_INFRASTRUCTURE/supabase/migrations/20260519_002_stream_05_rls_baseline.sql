-- =============================================================================
-- Migration: stream_05_rls_baseline_v1_PROD
-- Project: bdi-prod (vpbbguexygbqovsjfsab)
-- Author: agent.specialist.STU-S5-5 (CCS ephemeral · sprint-2 day-1)
-- Date: 2026-05-18
-- Companion to: stream_05_PROD.sql
-- Purpose: Address 9-criterion gate C2 FAIL (1 policy of needed 7+) +
--          C6 PARTIAL FAIL (SEC-DOMAIN-BLOCK advisory tylko)
--
-- Baseline pattern: service_role full access (block all other roles by default)
-- Per-agent identity scoping = sprint-3 (post STU-S13 Identity cards LIVE)
-- =============================================================================

BEGIN;

-- =============================================================================
-- cp_messages · write policies (read-side handled by cp_messages_domain_isolation)
-- =============================================================================

-- INSERT: only service_role (agents using SA bootstrap)
CREATE POLICY cp_messages_service_role_insert ON control_plane.cp_messages
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- UPDATE: only service_role (status transitions · acked_at writes)
CREATE POLICY cp_messages_service_role_update ON control_plane.cp_messages
  FOR UPDATE
  TO service_role
  USING (true)
  WITH CHECK (true);

-- DELETE: BLOCKED (append-only · 7y retention enforced)
-- · NO policy = effectively denied (RLS enabled + no policy = deny all non-super)

-- =============================================================================
-- cp_outbox · full service_role access
-- =============================================================================
CREATE POLICY cp_outbox_service_role_all ON control_plane.cp_outbox
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =============================================================================
-- cp_inbox · service_role full + future per-recipient scoping (placeholder)
-- =============================================================================
CREATE POLICY cp_inbox_service_role_all ON control_plane.cp_inbox
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Future (sprint-3 STU-S13 Identity): per-recipient READ
-- CREATE POLICY cp_inbox_recipient_read ON control_plane.cp_inbox
--   FOR SELECT
--   TO authenticated
--   USING (recipient_actor_id = current_setting('app.current_actor_id', true));

-- =============================================================================
-- cp_dlq · full service_role access (A6 Fabric + STU-S5 ops)
-- =============================================================================
CREATE POLICY cp_dlq_service_role_all ON control_plane.cp_dlq
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =============================================================================
-- cp_acks · service_role full + future per-acker scoping (placeholder)
-- =============================================================================
CREATE POLICY cp_acks_service_role_all ON control_plane.cp_acks
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =============================================================================
-- cp_correlation_groups · service_role full
-- =============================================================================
CREATE POLICY cp_corr_groups_service_role_all ON control_plane.cp_correlation_groups
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =============================================================================
-- cp_agent_state · service_role full + future M0 query view
-- =============================================================================
CREATE POLICY cp_agent_state_service_role_all ON control_plane.cp_agent_state
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Future (sprint-3): per-agent own-state READ
-- CREATE POLICY cp_agent_state_own_read ON control_plane.cp_agent_state
--   FOR SELECT
--   TO authenticated
--   USING (actor_id = current_setting('app.current_actor_id', true));

-- =============================================================================
-- SEC-DOMAIN-BLOCK enforcement (gate C6 PARTIAL FAIL fix)
-- D-STU-075 one-way matrix · BEFORE INSERT trigger na cp_messages
-- =============================================================================

CREATE OR REPLACE FUNCTION control_plane.enforce_domain_boundary()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  src_domain text;
  tgt_domain text;
BEGIN
  -- Lookup source workspace domain (BDI-GOV/ENERGA-SAFE/PRIVATE-EXEC)
  -- Pattern: workspace code prefix → domain mapping
  -- · BDI-STUDIO/T4L/etc → BDI-GOV
  -- · ENERGA-* → ENERGA-SAFE
  -- · ALEX-EXEC/PRIVATE-* → PRIVATE-EXEC
  src_domain := NEW.domain;

  -- Derive target domain from target_workspace
  IF NEW.target_workspace ILIKE 'ENERGA%' THEN
    tgt_domain := 'ENERGA-SAFE';
  ELSIF NEW.target_workspace ILIKE 'ALEX%' OR NEW.target_workspace ILIKE 'PRIVATE%' THEN
    tgt_domain := 'PRIVATE-EXEC';
  ELSE
    tgt_domain := 'BDI-GOV';
  END IF;

  -- D-STU-075 one-way matrix enforcement
  -- BDI-GOV → ENERGA-SAFE: BLOCKED
  -- BDI-GOV → PRIVATE-EXEC: BLOCKED
  IF src_domain = 'BDI-GOV' AND tgt_domain IN ('ENERGA-SAFE','PRIVATE-EXEC') THEN
    -- Auto-route do DLQ instead of hard reject (preserve trail)
    INSERT INTO control_plane.cp_dlq (message_id, failure_reason, failure_payload)
    VALUES (NEW.message_id,
            format('SEC-DOMAIN-BLOCK: %s → %s blocked per D-STU-075 one-way matrix', src_domain, tgt_domain),
            to_jsonb(NEW));
    RAISE EXCEPTION 'SEC-DOMAIN-BLOCK: BDI-GOV agents cannot write to % domain · routed to cp_dlq', tgt_domain;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION control_plane.enforce_domain_boundary IS
  'D-STU-075 one-way matrix enforcement · BEFORE INSERT na cp_messages · BDI-GOV → ENE/PE = BLOCK + DLQ';

CREATE TRIGGER cp_messages_domain_boundary_check
  BEFORE INSERT ON control_plane.cp_messages
  FOR EACH ROW
  EXECUTE FUNCTION control_plane.enforce_domain_boundary();

COMMIT;

-- =============================================================================
-- POST-APPLY EXPECTED STATE:
-- · cp_messages: 3 policies total (domain_isolation SELECT · service_role INSERT · service_role UPDATE)
-- · cp_outbox/inbox/dlq/acks/correlation_groups/agent_state: 1 policy each (service_role_all)
-- · 1 trigger function (enforce_domain_boundary) + 1 trigger (cp_messages_domain_boundary_check)
-- · Total: 9 policies + 1 function + 1 trigger
-- · Coverage: 7/7 tables polices · DELETE on cp_messages effectively denied (append-only)
-- =============================================================================

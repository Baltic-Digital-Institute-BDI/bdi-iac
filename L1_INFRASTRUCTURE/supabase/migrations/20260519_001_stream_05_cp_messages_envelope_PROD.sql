-- =============================================================================
-- Migration: stream_05_cross_laptop_message_envelope_v1_PROD
-- Project: bdi-prod (vpbbguexygbqovsjfsab)
-- Author: agent.specialist.STU-S5-5 (CCS ephemeral · sprint-2 day-1)
-- Date: 2026-05-18
-- Authority: kr_prime STOP-4 ratified (Variant B Amended) · D-STU-081 + D-STU-088
-- Source: replicate TEST adsdaehvvnwknjushshn migration 20260510185441
-- Improvements vs TEST:
--   1. Composite index (target_workspace, created_at DESC) added (gate C3 finding)
--   2. Redundant cp_messages_correlation_idx OMITTED (duplicate of PK)
-- Rollback: stream_05_ROLLBACK.sql (companion file)
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- Schema
-- -----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS control_plane;
COMMENT ON SCHEMA control_plane IS
  'Stream 5 cp_messages envelope · cross-laptop/cross-workspace message store · 7-year retention · Authority: D-STU-081';

-- -----------------------------------------------------------------------------
-- Table 1/7: control_plane.cp_messages (core envelope · 18 cols)
-- -----------------------------------------------------------------------------
CREATE TABLE control_plane.cp_messages (
  message_id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id              uuid        NOT NULL,
  correlation_id      uuid        NOT NULL,
  source_workspace    text        NOT NULL,
  target_workspace    text        NOT NULL,
  domain              text        NOT NULL CHECK (domain = ANY (ARRAY['BDI-GOV','ENERGA-SAFE','PRIVATE-EXEC'])),
  actor_type          text        NOT NULL CHECK (actor_type = ANY (ARRAY['HUM','CCA','CCS','N8N','OTH'])),
  actor_id            text        NOT NULL,
  device_id           text,
  sensitivity_level   text        NOT NULL CHECK (sensitivity_level = ANY (ARRAY['L0_PUBLIC','L1_INTERNAL','L2_CONFIDENTIAL','L3_SECRET','L4_RESTRICTED'])),
  message_type        text        NOT NULL,
  payload             jsonb       NOT NULL,
  artifact_uri        text,
  status              text        NOT NULL DEFAULT 'pending' CHECK (status = ANY (ARRAY['pending','sent','ack','fail','dlq','archived'])),
  ack_deadline        timestamptz,
  retention_class     text        NOT NULL DEFAULT '7y',
  created_at          timestamptz NOT NULL DEFAULT now(),
  acked_at            timestamptz
);
COMMENT ON TABLE control_plane.cp_messages IS
  'Główny store wszystkich cross-laptop / cross-workspace messages · append-only · 7-year retention';
ALTER TABLE control_plane.cp_messages ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table 2/7: control_plane.cp_outbox (retry/backpressure queue)
-- -----------------------------------------------------------------------------
CREATE TABLE control_plane.cp_outbox (
  outbox_id      uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id     uuid        NOT NULL REFERENCES control_plane.cp_messages(message_id) ON DELETE CASCADE,
  retry_count    integer     NOT NULL DEFAULT 0,
  next_retry_at  timestamptz,
  last_error     text,
  created_at     timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE control_plane.cp_outbox ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table 3/7: control_plane.cp_inbox (per-recipient delivery)
-- -----------------------------------------------------------------------------
CREATE TABLE control_plane.cp_inbox (
  inbox_id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id            uuid        NOT NULL REFERENCES control_plane.cp_messages(message_id) ON DELETE CASCADE,
  recipient_actor_id    text        NOT NULL,
  recipient_workspace   text        NOT NULL,
  delivered_at          timestamptz NOT NULL DEFAULT now(),
  read_at               timestamptz,
  acked_at              timestamptz
);
ALTER TABLE control_plane.cp_inbox ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table 4/7: control_plane.cp_dlq (Dead Letter Queue · envelope failures)
-- -----------------------------------------------------------------------------
CREATE TABLE control_plane.cp_dlq (
  dlq_id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id        uuid,
  failure_reason    text        NOT NULL,
  failure_payload   jsonb,
  retry_count       integer     NOT NULL DEFAULT 0,
  failed_at         timestamptz NOT NULL DEFAULT now(),
  resolved_at       timestamptz,
  resolution_notes  text
);
COMMENT ON TABLE control_plane.cp_dlq IS
  'Stream 5 envelope DLQ · NIE konflikt z fabric.dlq (A6 n8n workflow legacy) · see handshake doc';
ALTER TABLE control_plane.cp_dlq ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table 5/7: control_plane.cp_acks (acknowledgment ledger)
-- -----------------------------------------------------------------------------
CREATE TABLE control_plane.cp_acks (
  ack_id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id      uuid        NOT NULL REFERENCES control_plane.cp_messages(message_id) ON DELETE CASCADE,
  acker_actor_id  text        NOT NULL,
  ack_type        text        NOT NULL CHECK (ack_type = ANY (ARRAY['received','processed','rejected','expired'])),
  ack_metadata    jsonb,
  acked_at        timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE control_plane.cp_acks ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table 6/7: control_plane.cp_correlation_groups (chain tracking)
-- -----------------------------------------------------------------------------
CREATE TABLE control_plane.cp_correlation_groups (
  correlation_id          uuid        PRIMARY KEY,
  group_label             text,
  parent_correlation_id   uuid        REFERENCES control_plane.cp_correlation_groups(correlation_id),
  initiated_by_actor_id   text        NOT NULL,
  initiated_at            timestamptz NOT NULL DEFAULT now(),
  closed_at               timestamptz,
  message_count           integer     NOT NULL DEFAULT 0,
  metadata                jsonb
);
ALTER TABLE control_plane.cp_correlation_groups ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table 7/7: control_plane.cp_agent_state (heartbeat ledger)
-- -----------------------------------------------------------------------------
CREATE TABLE control_plane.cp_agent_state (
  state_id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id            text        NOT NULL,
  workspace           text        NOT NULL,
  domain              text        NOT NULL,
  device_id           text,
  health_status       text        NOT NULL CHECK (health_status = ANY (ARRAY['green','yellow','red','idle','offline'])),
  current_task        text,
  recent_decisions    jsonb,
  last_heartbeat_at   timestamptz NOT NULL DEFAULT now(),
  metadata            jsonb
);
COMMENT ON TABLE control_plane.cp_agent_state IS
  'Per-agent self-disclosure ledger · M0 query view · DLQ-to-state heartbeat';
ALTER TABLE control_plane.cp_agent_state ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- INDEXES (16 total · NIE redundant cp_messages_correlation_idx · NEW composite)
-- =============================================================================

-- cp_messages (7 indexes · skip redundant UNIQUE message_id which duplicates PK)
CREATE INDEX cp_messages_actor_id_idx          ON control_plane.cp_messages(actor_id);
CREATE INDEX cp_messages_correlation_id_idx    ON control_plane.cp_messages(correlation_id);
CREATE INDEX cp_messages_created_at_idx        ON control_plane.cp_messages(created_at DESC);
CREATE INDEX cp_messages_domain_sensitivity_idx ON control_plane.cp_messages(domain, sensitivity_level);
CREATE INDEX cp_messages_status_idx            ON control_plane.cp_messages(status);
CREATE INDEX cp_messages_target_workspace_idx  ON control_plane.cp_messages(target_workspace);
-- NEW (gate C3 improvement): composite for "messages dla workspace X sorted by time"
CREATE INDEX cp_messages_target_ws_created_idx ON control_plane.cp_messages(target_workspace, created_at DESC);

-- cp_outbox (2)
CREATE INDEX cp_outbox_message_id_idx  ON control_plane.cp_outbox(message_id);
CREATE INDEX cp_outbox_next_retry_idx  ON control_plane.cp_outbox(next_retry_at) WHERE next_retry_at IS NOT NULL;

-- cp_inbox (3 · 1 UNIQUE + 2 standard)
CREATE UNIQUE INDEX cp_inbox_message_recipient_unique ON control_plane.cp_inbox(message_id, recipient_actor_id);
CREATE INDEX cp_inbox_recipient_idx ON control_plane.cp_inbox(recipient_actor_id, recipient_workspace);
CREATE INDEX cp_inbox_unread_idx    ON control_plane.cp_inbox(recipient_actor_id) WHERE read_at IS NULL;

-- cp_dlq (1 partial)
CREATE INDEX cp_dlq_unresolved_idx ON control_plane.cp_dlq(failed_at DESC) WHERE resolved_at IS NULL;

-- cp_acks (1)
CREATE INDEX cp_acks_message_id_idx ON control_plane.cp_acks(message_id);

-- cp_agent_state (3)
CREATE INDEX cp_agent_state_actor_idx     ON control_plane.cp_agent_state(actor_id, last_heartbeat_at DESC);
CREATE INDEX cp_agent_state_workspace_idx ON control_plane.cp_agent_state(workspace, domain);
CREATE INDEX cp_agent_state_health_idx    ON control_plane.cp_agent_state(health_status);

-- =============================================================================
-- BASELINE RLS POLICY · cp_messages_domain_isolation (replicate TEST)
-- · per-table baseline policies w stream_05_rls_baseline.sql (companion)
-- =============================================================================

CREATE POLICY cp_messages_domain_isolation ON control_plane.cp_messages
  FOR SELECT
  USING (
    (domain = current_setting('app.current_domain', true))
    AND (sensitivity_level <= current_setting('app.current_clearance', true))
  );

COMMIT;

-- =============================================================================
-- POST-APPLY EXPECTED STATE:
-- · 7 tables w control_plane schema · all RLS enabled
-- · 17 indexes total (vs TEST 18 · -1 redundant + 1 new composite = net -0+1)
-- · 1 baseline policy (cp_messages_domain_isolation) · 6 more w companion file
-- · 0 rows (clean baseline · smoke INSERT post-RLS baseline apply)
-- =============================================================================

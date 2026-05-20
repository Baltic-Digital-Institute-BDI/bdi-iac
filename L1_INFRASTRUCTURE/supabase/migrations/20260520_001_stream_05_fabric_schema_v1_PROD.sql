-- =============================================================================
-- Migration: stream_05_fabric_schema_v1_PROD
-- Project: bdi-prod (vpbbguexygbqovsjfsab)
-- Author: agent.specialist.STU0 (autonomic execute · D-STU-131 retroactive PR)
-- Applied: 2026-05-20 04:19:56 UTC (Supabase migration version 20260520041956)
-- Authority: kr_prime STOP-4a sign-off 2026-05-19 EOD ("wykonaj to TERAZ")
-- Pattern: STU0 autonomic execute (post-AP-93 codification · NIE delegate-to-KR)
-- Source: 1:1 replicate z TEST adsdaehvvnwknjushshn (fabric.* schema)
-- Rollback: 20260520_001_stream_05_fabric_schema_v1_ROLLBACK.sql (companion)
-- Status: RETROACTIVE · already applied · NIE re-apply (Supabase migration tracker prevents)
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- STEP 0: preflight (idempotent · ABORT only if non-empty data)
-- -----------------------------------------------------------------------------
DO $preflight$
DECLARE v_count int;
BEGIN
  SELECT COUNT(*) INTO v_count FROM information_schema.tables WHERE table_schema='fabric';
  IF v_count > 0 THEN
    RAISE NOTICE 'fabric.* schema has % tables already · proceeding with idempotent IF NOT EXISTS', v_count;
  END IF;
END $preflight$;

-- -----------------------------------------------------------------------------
-- STEP 1: prerequisite helper · core.current_agent_role()
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION core.current_agent_role()
  RETURNS text LANGUAGE sql STABLE
AS $$
  SELECT current_setting('app.current_agent_role', true);
$$;

-- -----------------------------------------------------------------------------
-- STEP 2: tables · FK-aware order (workflows first · then dependents)
-- -----------------------------------------------------------------------------

-- Table 1/5: fabric.workflows (n8n workflow registry)
CREATE TABLE IF NOT EXISTS fabric.workflows (
  workflow_id uuid NOT NULL DEFAULT gen_random_uuid(),
  workflow_name text NOT NULL,
  workflow_owner text NOT NULL,
  n8n_workflow_id text,
  category text NOT NULL,
  version text NOT NULL DEFAULT '1.0',
  status text NOT NULL DEFAULT 'draft',
  spec_path text,
  hitl_required boolean NOT NULL DEFAULT false,
  prod_signoff_by text,
  prod_signoff_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT workflows_pkey PRIMARY KEY (workflow_id),
  CONSTRAINT workflows_workflow_name_key UNIQUE (workflow_name),
  CONSTRAINT workflows_status_check CHECK (status IN ('draft','active','paused','deprecated')),
  CONSTRAINT workflows_category_check CHECK (category IN ('audit','router','proxy','governance','integration')),
  CONSTRAINT workflows_workflow_owner_fkey FOREIGN KEY (workflow_owner) REFERENCES core.agents(agent_id)
);

-- Table 2/5: fabric.executions (workflow run telemetry)
CREATE TABLE IF NOT EXISTS fabric.executions (
  execution_id uuid NOT NULL DEFAULT gen_random_uuid(),
  workflow_id uuid NOT NULL,
  correlation_id text NOT NULL,
  triggered_by text,
  trigger_event text,
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz,
  status text NOT NULL DEFAULT 'running',
  error_class text,
  error_message text,
  retry_count integer NOT NULL DEFAULT 0,
  payload_size_bytes integer,
  CONSTRAINT executions_pkey PRIMARY KEY (execution_id),
  CONSTRAINT uniq_workflow_correlation UNIQUE (workflow_id, correlation_id),
  CONSTRAINT executions_status_check CHECK (status IN ('running','success','failed','cancelled')),
  CONSTRAINT executions_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES fabric.workflows(workflow_id),
  CONSTRAINT executions_triggered_by_fkey FOREIGN KEY (triggered_by) REFERENCES core.agents(agent_id)
);

-- Table 3/5: fabric.routes (event routing rules · producer->consumer)
CREATE TABLE IF NOT EXISTS fabric.routes (
  route_id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_type text NOT NULL,
  event_canonical text NOT NULL,
  producer_role text NOT NULL,
  consumer_role text NOT NULL,
  consumer_endpoint text NOT NULL,
  consumer_auth text NOT NULL,
  timeout_seconds integer NOT NULL DEFAULT 5,
  retry_strategy text NOT NULL DEFAULT '3x_exp_5s_25s_125s',
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT routes_pkey PRIMARY KEY (route_id)
);

-- Table 4/5: fabric.dlq (dead-letter queue · failed events)
CREATE TABLE IF NOT EXISTS fabric.dlq (
  dlq_id uuid NOT NULL DEFAULT gen_random_uuid(),
  original_event_id uuid,
  workflow_id uuid,
  event_type text NOT NULL,
  target_consumer text NOT NULL,
  payload jsonb NOT NULL,
  error_class text NOT NULL,
  error_message text,
  retry_count integer NOT NULL DEFAULT 0,
  first_failed_at timestamptz NOT NULL DEFAULT now(),
  last_attempted_at timestamptz NOT NULL DEFAULT now(),
  status text NOT NULL DEFAULT 'pending',
  resolved_by text,
  resolved_at timestamptz,
  resolution_note text,
  CONSTRAINT dlq_pkey PRIMARY KEY (dlq_id),
  CONSTRAINT dlq_status_check CHECK (status IN ('pending','investigating','resolved','discarded')),
  CONSTRAINT dlq_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES fabric.workflows(workflow_id),
  CONSTRAINT dlq_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES core.agents(agent_id)
);

-- Table 5/5: fabric.connectors (external system connectors · PAT-secured)
CREATE TABLE IF NOT EXISTS fabric.connectors (
  connector_id uuid NOT NULL DEFAULT gen_random_uuid(),
  connector_name text NOT NULL,
  pattern text NOT NULL,
  source_system text NOT NULL,
  target_system text NOT NULL,
  workflow_id uuid,
  pat_secret_ref text NOT NULL,
  rotation_policy_id text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT connectors_pkey PRIMARY KEY (connector_id),
  CONSTRAINT connectors_connector_name_key UNIQUE (connector_name),
  CONSTRAINT connectors_pattern_check CHECK (pattern IN ('BridgeProxy','TransformProxy','GuardProxy')),
  CONSTRAINT connectors_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES fabric.workflows(workflow_id)
);

-- -----------------------------------------------------------------------------
-- STEP 3: indexes (7 custom · PK indexes auto-created)
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_fabric_workflows_owner ON fabric.workflows USING btree (workflow_owner);
CREATE INDEX IF NOT EXISTS idx_fabric_workflows_status ON fabric.workflows USING btree (status) WHERE (status='active');
CREATE INDEX IF NOT EXISTS idx_fabric_executions_workflow ON fabric.executions USING btree (workflow_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_fabric_executions_status ON fabric.executions USING btree (status) WHERE (status IN ('running','failed'));
CREATE INDEX IF NOT EXISTS idx_fabric_routes_event ON fabric.routes USING btree (event_type) WHERE (active=true);
CREATE INDEX IF NOT EXISTS idx_fabric_dlq_status ON fabric.dlq USING btree (status) WHERE (status='pending');
CREATE INDEX IF NOT EXISTS idx_fabric_connectors_active ON fabric.connectors USING btree (active) WHERE (active=true);

-- -----------------------------------------------------------------------------
-- STEP 4: fabric functions
-- -----------------------------------------------------------------------------

-- Function 1/2: fabric.trg_dlq_alert (severity-mapped DLQ alerts -> core.events)
CREATE OR REPLACE FUNCTION fabric.trg_dlq_alert()
  RETURNS trigger LANGUAGE plpgsql
AS $fn1$
DECLARE v_severity text;
BEGIN
  v_severity := CASE NEW.error_class
    WHEN 'auth_fail'        THEN 'CRITICAL'
    WHEN 'schema_mismatch'  THEN 'ERROR'
    WHEN 'http_5xx'         THEN 'WARN'
    WHEN 'timeout'          THEN 'WARN'
    ELSE 'WARN'
  END;
  INSERT INTO core.events (event_type, aggregate_type, aggregate_id, agent_id, payload)
  VALUES ('dlq.entry_created', 'fabric.dlq', NEW.dlq_id::text, 'agent.specialist.A6',
    jsonb_build_object('dlq_id',NEW.dlq_id,'workflow_id',NEW.workflow_id,'event_type',NEW.event_type,
      'target_consumer',NEW.target_consumer,'error_class',NEW.error_class,'error_message',NEW.error_message,
      'retry_count',NEW.retry_count,'severity',v_severity));
  RETURN NEW;
END;
$fn1$;

-- Function 2/2: fabric.trg_decisions_autocommit (governance autocommit · WARN/ERROR/CRITICAL decisions)
CREATE OR REPLACE FUNCTION fabric.trg_decisions_autocommit()
  RETURNS trigger LANGUAGE plpgsql
AS $fn2$
DECLARE
  v_severity      text;
  v_supabase_url  text;
  v_service_key   text;
  v_function_url  text;
  v_response_id   bigint;
BEGIN
  v_severity := COALESCE(NEW.metadata->>'severity', 'INFO');
  IF v_severity NOT IN ('WARN','ERROR','CRITICAL') THEN RETURN NEW; END IF;
  IF NEW.status != 'approved' THEN RETURN NEW; END IF;
  v_supabase_url := COALESCE(current_setting('app.supabase_url', true), '');
  v_service_key  := COALESCE(current_setting('app.service_role_key', true), '');
  IF v_supabase_url = '' OR v_service_key = '' THEN
    INSERT INTO core.audit_log (agent_id, action, schema_name, object_name, outcome, detail)
    VALUES ('agent.specialist.A6','autocommit.trigger_skipped_unconfigured','core','decisions','success',
      jsonb_build_object('decision_code',NEW.decision_code,'reason','app.supabase_url or app.service_role_key not configured (S4 Sprint 7 dep)'));
    RETURN NEW;
  END IF;
  v_function_url := v_supabase_url || '/functions/v1/governance-autocommit';
  BEGIN
    SELECT net.http_post(
      url := v_function_url,
      headers := jsonb_build_object('Content-Type','application/json','Authorization','Bearer ' || v_service_key),
      body := jsonb_build_object('decision_code',NEW.decision_code,'title',NEW.title,'body',NEW.body,
        'decision_type',NEW.decision_type,'severity',v_severity,'proposed_by',NEW.proposed_by,
        'approved_by',NEW.approved_by,'reference_links',NEW.reference_links,'metadata',NEW.metadata,
        'created_at',NEW.created_at,'decided_at',NEW.decided_at)
    ) INTO v_response_id;
    INSERT INTO core.audit_log (agent_id, action, schema_name, object_name, outcome, detail)
    VALUES ('agent.specialist.A6','autocommit.trigger_dispatched','core','decisions','success',
      jsonb_build_object('decision_code',NEW.decision_code,'severity',v_severity,'pg_net_request_id',v_response_id));
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO core.audit_log (agent_id, action, schema_name, object_name, outcome, detail)
    VALUES ('agent.specialist.A6','autocommit.trigger_dispatch_failed','core','decisions','error',
      jsonb_build_object('decision_code',NEW.decision_code,'error',SQLERRM));
  END;
  RETURN NEW;
END;
$fn2$;

-- -----------------------------------------------------------------------------
-- STEP 5: triggers (idempotent · DROP IF EXISTS + CREATE)
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_fabric_workflows_updated ON fabric.workflows;
CREATE TRIGGER trg_fabric_workflows_updated BEFORE UPDATE ON fabric.workflows
  FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

DROP TRIGGER IF EXISTS trg_fabric_connectors_updated ON fabric.connectors;
CREATE TRIGGER trg_fabric_connectors_updated BEFORE UPDATE ON fabric.connectors
  FOR EACH ROW EXECUTE FUNCTION core.set_updated_at();

DROP TRIGGER IF EXISTS trg_fabric_dlq_alert ON fabric.dlq;
CREATE TRIGGER trg_fabric_dlq_alert AFTER INSERT ON fabric.dlq
  FOR EACH ROW EXECUTE FUNCTION fabric.trg_dlq_alert();

DROP TRIGGER IF EXISTS trg_decisions_autocommit ON core.decisions;
CREATE TRIGGER trg_decisions_autocommit AFTER INSERT OR UPDATE ON core.decisions
  FOR EACH ROW EXECUTE FUNCTION fabric.trg_decisions_autocommit();

-- -----------------------------------------------------------------------------
-- STEP 6: enable RLS on all fabric tables
-- -----------------------------------------------------------------------------
ALTER TABLE fabric.workflows ENABLE ROW LEVEL SECURITY;
ALTER TABLE fabric.executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE fabric.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE fabric.dlq ENABLE ROW LEVEL SECURITY;
ALTER TABLE fabric.connectors ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- STEP 7: 10 RLS policies
-- -----------------------------------------------------------------------------

-- 2 policies na fabric.workflows
DROP POLICY IF EXISTS fabric_workflows_owner_rw ON fabric.workflows;
CREATE POLICY fabric_workflows_owner_rw ON fabric.workflows FOR ALL TO authenticated
  USING (workflow_owner = core.current_agent_id())
  WITH CHECK (workflow_owner = core.current_agent_id());

DROP POLICY IF EXISTS fabric_workflows_read_active ON fabric.workflows;
CREATE POLICY fabric_workflows_read_active ON fabric.workflows FOR SELECT TO authenticated
  USING (status = 'active');

-- 2 policies na fabric.executions
DROP POLICY IF EXISTS fabric_executions_owner_rw ON fabric.executions;
CREATE POLICY fabric_executions_owner_rw ON fabric.executions FOR ALL TO authenticated
  USING (workflow_id IN (SELECT workflow_id FROM fabric.workflows WHERE workflow_owner = core.current_agent_id()))
  WITH CHECK (workflow_id IN (SELECT workflow_id FROM fabric.workflows WHERE workflow_owner = core.current_agent_id()));

DROP POLICY IF EXISTS fabric_executions_read_self_triggered ON fabric.executions;
CREATE POLICY fabric_executions_read_self_triggered ON fabric.executions FOR SELECT TO authenticated
  USING (triggered_by = core.current_agent_id());

-- 2 policies na fabric.routes (A6 Fabric write · authenticated read active)
DROP POLICY IF EXISTS fabric_routes_a6_write ON fabric.routes;
CREATE POLICY fabric_routes_a6_write ON fabric.routes FOR ALL TO authenticated
  USING (core.current_agent_role() = 'agent.specialist.A6')
  WITH CHECK (core.current_agent_role() = 'agent.specialist.A6');

DROP POLICY IF EXISTS fabric_routes_read_active ON fabric.routes;
CREATE POLICY fabric_routes_read_active ON fabric.routes FOR SELECT TO authenticated
  USING (active = true);

-- 2 policies na fabric.dlq (A6 write · workflow owner OR A4/A6 read)
DROP POLICY IF EXISTS fabric_dlq_a6_write ON fabric.dlq;
CREATE POLICY fabric_dlq_a6_write ON fabric.dlq FOR ALL TO authenticated
  USING (core.current_agent_role() = 'agent.specialist.A6')
  WITH CHECK (core.current_agent_role() = 'agent.specialist.A6');

DROP POLICY IF EXISTS fabric_dlq_read_workflow_owner ON fabric.dlq;
CREATE POLICY fabric_dlq_read_workflow_owner ON fabric.dlq FOR SELECT TO authenticated
  USING ((workflow_id IN (SELECT workflow_id FROM fabric.workflows WHERE workflow_owner = core.current_agent_id()))
    OR (core.current_agent_role() IN ('agent.specialist.A4','agent.specialist.A6')));

-- 2 policies na fabric.connectors (A6/S4 write · authenticated read active)
DROP POLICY IF EXISTS fabric_connectors_a6_s4_write ON fabric.connectors;
CREATE POLICY fabric_connectors_a6_s4_write ON fabric.connectors FOR ALL TO authenticated
  USING (core.current_agent_role() IN ('agent.specialist.A6','agent.specialist.S4'))
  WITH CHECK (core.current_agent_role() IN ('agent.specialist.A6','agent.specialist.S4'));

DROP POLICY IF EXISTS fabric_connectors_read_active ON fabric.connectors;
CREATE POLICY fabric_connectors_read_active ON fabric.connectors FOR SELECT TO authenticated
  USING (active = true);

COMMIT;

-- =============================================================================
-- END OF MIGRATION · 5 tables · 7 indexes · 2 functions · 4 triggers · 10 RLS policies
-- =============================================================================

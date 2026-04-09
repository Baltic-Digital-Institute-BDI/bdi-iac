-- HIGH-014 W8.02 Migration 002: Create lab_access_domains (12 DAG domains)
-- Date:    2026-04-09
-- Author:  Claude agent (HIGH-014)
-- Why:     The 12 "access domains" from dependency-dag.yaml define WHAT a user
--          can see/edit. These are orthogonal to the 11 "data domains" in
--          plc_domain_registry (which map tables to registries).
--
-- Decision ref: HIGH-014 Decision Document, Decision 3 (KR: TAK)

BEGIN;

-- ── 1. Create access domains table ──
CREATE TABLE IF NOT EXISTS lab_console.lab_access_domains (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  domain_key  text NOT NULL UNIQUE,
  display_name text NOT NULL,
  description text,
  icon        text,           -- lucide icon name for UI
  sort_order  int DEFAULT 0,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

COMMENT ON TABLE lab_console.lab_access_domains IS
  'W8.02: 12 access domains (business responsibility areas). Separate from plc_domain_registry (data registries).';

-- ── 2. Seed 12 DAG access domains ──
INSERT INTO lab_console.lab_access_domains (domain_key, display_name, description, icon, sort_order)
VALUES
  ('business',    'Business',        'Business model, strategy, partnerships',     'briefcase',      1),
  ('product',     'Product',         'Product lifecycle, features, roadmap',       'package',        2),
  ('operations',  'Operations',      'Day-to-day ops, SLAs, incident management', 'settings',       3),
  ('architecture','Architecture',    'System design, ADRs, tech debt',            'building-2',     4),
  ('security',    'Security',        'IAM, secrets, compliance, audit',           'shield',         5),
  ('tech_stack',  'Tech Stack',      'Languages, frameworks, infrastructure',     'layers',         6),
  ('devops',      'DevOps',          'CI/CD, IaC, deployments, environments',     'git-branch',     7),
  ('testing',     'Testing',         'QA, test suites, coverage, UAT',            'test-tube',      8),
  ('compliance',  'Compliance',      'Legal, regulatory, GDPR, standards',        'file-check',     9),
  ('monitoring',  'Monitoring',      'Observability, alerts, dashboards, DORA',   'activity',      10),
  ('external',    'External',        'Vendors, APIs, integrations, SaaS',         'globe',         11),
  ('feedback',    'Feedback',        'User feedback, NPS, feature requests',      'message-circle',12)
ON CONFLICT (domain_key) DO NOTHING;

-- ── 3. Enable RLS ──
ALTER TABLE lab_console.lab_access_domains ENABLE ROW LEVEL SECURITY;

-- Read: any authenticated user
CREATE POLICY lab_access_domains_auth_select ON lab_console.lab_access_domains
  FOR SELECT TO authenticated
  USING (auth.uid() IS NOT NULL);

-- Admin: full CRUD
CREATE POLICY lab_access_domains_admin_all ON lab_console.lab_access_domains
  FOR ALL TO authenticated
  USING (lab_console.is_admin())
  WITH CHECK (lab_console.is_admin());

COMMIT;

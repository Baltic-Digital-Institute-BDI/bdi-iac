-- HIGH-014 W8.02 Migration 004: Seed users Adam + Olga + domain assignments
-- Date:    2026-04-09
-- Author:  Claude agent (HIGH-014)
-- Why:     Adam and Olga don't exist in lab_users (only in CF Access policies).
--          This creates their lab_console profiles and assigns domains.
--
-- NOTE: auth_id is NULL because they don't have auth.users accounts yet.
--       When they first log in via CF Access + Supabase OTP, auth_id will be
--       linked by the Console app (match by email).
--
-- Decision ref: DAG iam_model, 3 seed users

BEGIN;

-- ── 1. Insert Adam (admin) ──
INSERT INTO lab_console.lab_users (email, display_name, role, is_active)
VALUES ('it@baltic-digital.org', 'Adam', 'admin', true)
ON CONFLICT DO NOTHING;

-- ── 2. Insert Olga (editor) ──
INSERT INTO lab_console.lab_users (email, display_name, role, is_active)
VALUES ('olga@baltic-digital.org', 'Olga', 'editor', true)
ON CONFLICT DO NOTHING;

-- ── 3. KR (super_admin) gets ALL 12 domains with admin access ──
INSERT INTO lab_console.lab_user_domain_access (user_id, domain_id, access_level, granted_by)
SELECT
  u.id,
  d.id,
  'admin',
  u.id  -- self-granted (bootstrap)
FROM lab_console.lab_users u
CROSS JOIN lab_console.lab_access_domains d
WHERE u.email = 'krzysztof@baltic-digital.org'
ON CONFLICT (user_id, domain_id) DO NOTHING;

-- ── 4. Adam (admin) gets assigned domains ──
-- security, devops, architecture, tech_stack, monitoring, operations
INSERT INTO lab_console.lab_user_domain_access (user_id, domain_id, access_level, granted_by)
SELECT
  u.id,
  d.id,
  'admin',
  (SELECT id FROM lab_console.lab_users WHERE email = 'krzysztof@baltic-digital.org')
FROM lab_console.lab_users u
CROSS JOIN lab_console.lab_access_domains d
WHERE u.email = 'it@baltic-digital.org'
  AND d.domain_key IN ('security', 'devops', 'architecture', 'tech_stack', 'monitoring', 'operations')
ON CONFLICT (user_id, domain_id) DO NOTHING;

-- ── 5. Olga (editor) gets assigned domains ──
-- product, business, feedback, compliance, external, testing
INSERT INTO lab_console.lab_user_domain_access (user_id, domain_id, access_level, granted_by)
SELECT
  u.id,
  d.id,
  'write',
  (SELECT id FROM lab_console.lab_users WHERE email = 'krzysztof@baltic-digital.org')
FROM lab_console.lab_users u
CROSS JOIN lab_console.lab_access_domains d
WHERE u.email = 'olga@baltic-digital.org'
  AND d.domain_key IN ('product', 'business', 'feedback', 'compliance', 'external', 'testing')
ON CONFLICT (user_id, domain_id) DO NOTHING;

COMMIT;

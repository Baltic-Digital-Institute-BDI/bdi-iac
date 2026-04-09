-- HIGH-014 W8.02 Migration 003: Create lab_user_domain_access
-- Date:    2026-04-09
-- Author:  Claude agent (HIGH-014)
-- Why:     Maps users to access domains with specific permission levels.
--          A user with role='editor' can only edit data in their assigned domains.
--
-- Example: Adam (admin) → security, devops, architecture → full access
--          Olga (editor) → product, business, feedback → edit access

BEGIN;

-- ── 1. Create user ↔ domain mapping table ──
CREATE TABLE IF NOT EXISTS lab_console.lab_user_domain_access (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES lab_console.lab_users(id) ON DELETE CASCADE,
  domain_id   uuid NOT NULL REFERENCES lab_console.lab_access_domains(id) ON DELETE CASCADE,
  access_level text NOT NULL DEFAULT 'read'
    CHECK (access_level IN ('read', 'write', 'admin')),
  granted_by  uuid REFERENCES lab_console.lab_users(id),
  granted_at  timestamptz DEFAULT now(),
  expires_at  timestamptz,  -- NULL = never expires
  UNIQUE (user_id, domain_id)
);

COMMENT ON TABLE lab_console.lab_user_domain_access IS
  'W8.02: Maps users to access domains with permission level (read/write/admin).';

CREATE INDEX idx_user_domain_access_user ON lab_console.lab_user_domain_access(user_id);
CREATE INDEX idx_user_domain_access_domain ON lab_console.lab_user_domain_access(domain_id);

-- ── 2. Helper: check if current user has access to a domain ──
CREATE OR REPLACE FUNCTION lab_console.has_domain_access(p_domain_key text, p_min_level text DEFAULT 'read')
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = lab_console
AS $$
  SELECT COALESCE(
    (
      -- super_admin has access to everything
      SELECT true FROM lab_console.lab_users
      WHERE auth_id = (SELECT auth.uid())::text
        AND is_active = true
        AND role = 'super_admin'
      LIMIT 1
    ),
    (
      -- Check domain assignment
      SELECT true FROM lab_console.lab_user_domain_access uda
      JOIN lab_console.lab_users u ON u.id = uda.user_id
      JOIN lab_console.lab_access_domains d ON d.id = uda.domain_id
      WHERE u.auth_id = (SELECT auth.uid())::text
        AND u.is_active = true
        AND d.domain_key = p_domain_key
        AND d.is_active = true
        AND (uda.expires_at IS NULL OR uda.expires_at > now())
        AND CASE p_min_level
              WHEN 'read'  THEN uda.access_level IN ('read', 'write', 'admin')
              WHEN 'write' THEN uda.access_level IN ('write', 'admin')
              WHEN 'admin' THEN uda.access_level = 'admin'
              ELSE false
            END
      LIMIT 1
    ),
    false
  );
$$;

GRANT EXECUTE ON FUNCTION lab_console.has_domain_access(text, text) TO authenticated;

-- ── 3. Enable RLS ──
ALTER TABLE lab_console.lab_user_domain_access ENABLE ROW LEVEL SECURITY;

-- Users can see their own domain assignments
CREATE POLICY uda_self_select ON lab_console.lab_user_domain_access
  FOR SELECT TO authenticated
  USING (
    user_id = lab_console.get_user_id()
    OR lab_console.is_admin()
  );

-- Only admins can manage domain assignments
CREATE POLICY uda_admin_all ON lab_console.lab_user_domain_access
  FOR ALL TO authenticated
  USING (lab_console.is_admin())
  WITH CHECK (lab_console.is_admin());

COMMIT;

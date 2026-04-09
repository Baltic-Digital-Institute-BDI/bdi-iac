-- HIGH-014 W8.02 Migration 001: Fix is_admin() + add is_super_admin()
-- Date:    2026-04-09
-- Author:  Claude agent (HIGH-014)
-- Why:     is_admin() only checks role='admin', returns FALSE for super_admin.
--          KR has role='super_admin' in lab_users → is_admin() = false → broken.
--
-- Changes:
--   1. Replace is_admin() → checks role IN ('admin','super_admin')
--   2. Add is_super_admin() → checks role = 'super_admin'
--   3. Add has_role(text[]) → generic role checker for RLS policies
--   4. Add get_user_email() → returns email from lab_users (for audit)

BEGIN;

-- ── 1. Fix is_admin() — CRITICAL BUG FIX ──
CREATE OR REPLACE FUNCTION lab_console.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = lab_console
AS $$
  SELECT COALESCE(
    (SELECT role IN ('admin', 'super_admin') FROM lab_console.lab_users
     WHERE auth_id = (SELECT auth.uid())::text
     AND is_active = true
     LIMIT 1),
    false
  );
$$;

-- ── 2. New: is_super_admin() ──
CREATE OR REPLACE FUNCTION lab_console.is_super_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = lab_console
AS $$
  SELECT COALESCE(
    (SELECT role = 'super_admin' FROM lab_console.lab_users
     WHERE auth_id = (SELECT auth.uid())::text
     AND is_active = true
     LIMIT 1),
    false
  );
$$;

-- ── 3. New: has_role(roles text[]) — generic role matcher ──
CREATE OR REPLACE FUNCTION lab_console.has_role(allowed_roles text[])
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = lab_console
AS $$
  SELECT COALESCE(
    (SELECT role = ANY(allowed_roles) FROM lab_console.lab_users
     WHERE auth_id = (SELECT auth.uid())::text
     AND is_active = true
     LIMIT 1),
    false
  );
$$;

-- ── 4. New: get_user_email() ──
CREATE OR REPLACE FUNCTION lab_console.get_user_email()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = lab_console
AS $$
  SELECT email FROM lab_console.lab_users
  WHERE auth_id = (SELECT auth.uid())::text
  AND is_active = true
  LIMIT 1;
$$;

-- ── 5. Grant execute to authenticated role ──
GRANT EXECUTE ON FUNCTION lab_console.is_super_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION lab_console.has_role(text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION lab_console.get_user_email() TO authenticated;

COMMIT;

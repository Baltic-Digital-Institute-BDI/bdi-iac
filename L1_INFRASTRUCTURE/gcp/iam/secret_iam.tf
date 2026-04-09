# =============================================================================
# BDI Infrastructure — Per-Secret IAM Bindings
# HIGH-014 W8.02 Identity-as-Code
# Generated: 2026-04-09 from live GCP discovery (per-secret get-iam-policy)
# =============================================================================
# Least-privilege pattern:
#   sa-console-dev     → secretAccessor on dev-console-* secrets (7)
#   sa-console-staging → secretAccessor on staging-console-* secrets (7)
#   sa-console-prod    → secretAccessor on prod-console-* secrets (18)
#
# Total: 32 per-secret IAM bindings
# =============================================================================

# ─── Local Variables ─────────────────────────────────────────────────────────

locals {
  # dev secrets → sa-console-dev
  dev_secrets = [
    "dev-console-anthropic-api-key",
    "dev-console-n8n-api-key",
    "dev-console-openai-api-key",
    "dev-console-supabase-anon-key",
    "dev-console-supabase-db-connection-string",
    "dev-console-supabase-publishable-key",
    "dev-console-supabase-url",
  ]

  # staging secrets → sa-console-staging
  staging_secrets = [
    "staging-console-anthropic-api-key",
    "staging-console-n8n-api-key",
    "staging-console-openai-api-key",
    "staging-console-supabase-anon-key",
    "staging-console-supabase-db-connection-string",
    "staging-console-supabase-publishable-key",
    "staging-console-supabase-url",
  ]

  # prod secrets → sa-console-prod
  prod_secrets = [
    "prod-console-anthropic-api-key",
    "prod-console-cf-access-client-id",
    "prod-console-cf-access-client-secret",
    "prod-console-clickup-api-token",
    "prod-console-n8n-api-key",
    "prod-console-n8n-api-url",
    "prod-console-n8n-gmail-oauth",
    "prod-console-n8n-google-drive-oauth",
    "prod-console-n8n-ms-teams-oauth",
    "prod-console-n8n-supabase-api-key",
    "prod-console-n8n-zoho-crm-oauth",
    "prod-console-openai-api-key",
    "prod-console-supabase-anon-key",
    "prod-console-supabase-db-connection-string",
    "prod-console-supabase-db-password",
    "prod-console-supabase-publishable-key",
    "prod-console-supabase-service-role-key",
    "prod-console-supabase-url",
  ]
}

# ─── Dev Environment Secret Bindings ────────────────────────────────────────

resource "google_secret_manager_secret_iam_member" "dev_console" {
  for_each  = toset(local.dev_secrets)
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.sa_console_dev.email}"
}

# ─── Staging Environment Secret Bindings ────────────────────────────────────

resource "google_secret_manager_secret_iam_member" "staging_console" {
  for_each  = toset(local.staging_secrets)
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.sa_console_staging.email}"
}

# ─── Prod Environment Secret Bindings ───────────────────────────────────────

resource "google_secret_manager_secret_iam_member" "prod_console" {
  for_each  = toset(local.prod_secrets)
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.sa_console_prod.email}"
}

# ─── Outputs ─────────────────────────────────────────────────────────────────

output "per_secret_binding_count" {
  description = "Total per-secret IAM bindings"
  value       = length(local.dev_secrets) + length(local.staging_secrets) + length(local.prod_secrets)
}

# Target: bdi-iac/terraform/integrations/eka-supabase-auth/ (written to e-kancelaria/ due to FUSE lock)

# EKA-AUTH: Supabase Auth URL Config + OAuth Providers
# Scope: Configures site_url, redirect_urls, and OAuth for e-Kancelaria
#         across a SINGLE Supabase project (call once per env).
#
# IMPORTANT: Supabase projects are SHARED across BDI products.
#            redirect_urls are ADDITIVE — existing Lab Console URLs must be
#            included in var.all_redirect_urls to avoid overwrite.

module "auth_config" {
  source = "../../../_OUTPUTS/S05/bdi-iac-export/terraform/modules/supabase-auth-config"

  project_ref = var.supabase_project_ref

  # site_url remains the primary product's URL for this project.
  # For shared projects, this should be the "primary" product or left unchanged.
  site_url       = var.site_url
  redirect_urls  = var.all_redirect_urls
  disable_signup = var.disable_signup

  # Google OAuth
  google_enabled   = var.google_enabled
  google_client_id = var.google_client_id
  google_secret    = var.google_secret

  # Microsoft/Azure OAuth
  azure_enabled   = var.azure_enabled
  azure_client_id = var.azure_client_id
  azure_secret    = var.azure_secret
  azure_url       = var.azure_url
}

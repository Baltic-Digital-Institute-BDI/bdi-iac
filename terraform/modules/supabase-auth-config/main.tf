##############################################################################
# BDI Terraform Module — Supabase Auth Config
# Standard: BDI-IaC-Convention v1.0 | IAC-01, IAC-04
#
# Purpose: Universal module for configuring Supabase Auth settings per project.
#          Manages: site_url, redirect_urls, OAuth providers (Google, Microsoft).
#          Uses native supabase_settings resource (auth = jsonencode).
#
# API ref: PATCH /v1/projects/{ref}/config/auth
# TF ref:  registry.terraform.io/providers/supabase/supabase/latest/docs/resources/settings
##############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = ">= 1.0.0"
    }
  }
}

# ─── Locals: build auth config object ────────────────────────────────────────

locals {
  # Base auth config — always present
  base_auth = {
    site_url       = var.site_url
    uri_allow_list = join(",", var.redirect_urls)
    disable_signup = var.disable_signup
  }

  # Google OAuth — conditionally merged
  google_auth = var.google_enabled ? {
    external_google_enabled  = true
    external_google_client_id = var.google_client_id
    external_google_secret    = var.google_secret
  } : {}

  # Microsoft/Azure OAuth — conditionally merged
  azure_auth = var.azure_enabled ? {
    external_azure_enabled   = true
    external_azure_client_id = var.azure_client_id
    external_azure_secret    = var.azure_secret
    external_azure_url       = var.azure_url
  } : {}

  # Final merged config
  auth_config = merge(local.base_auth, local.google_auth, local.azure_auth)
}

# ─── Supabase Settings Resource ──────────────────────────────────────────────

resource "supabase_settings" "auth" {
  project_ref = var.project_ref

  auth = jsonencode(local.auth_config)

  lifecycle {
    # Prevent Terraform from clobbering unmanaged settings (e.g. MFA, email)
    # by only tracking fields we explicitly set.
    ignore_changes = []
  }
}

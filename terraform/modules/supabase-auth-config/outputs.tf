##############################################################################
# BDI Terraform Module — Supabase Auth Config Outputs
##############################################################################

output "project_ref" {
  description = "Supabase project reference (pass-through)"
  value       = var.project_ref
}

output "site_url" {
  description = "Configured site_url"
  value       = var.site_url
}

output "redirect_urls" {
  description = "List of configured redirect URLs"
  value       = var.redirect_urls
}

output "google_enabled" {
  description = "Whether Google OAuth is enabled"
  value       = var.google_enabled
}

output "azure_enabled" {
  description = "Whether Microsoft/Azure OAuth is enabled"
  value       = var.azure_enabled
}

output "auth_config_json" {
  description = "Full auth config as JSON (for debugging — contains secrets)"
  value       = jsonencode(local.auth_config)
  sensitive   = true
}

# Target: bdi-iac/terraform/integrations/eka-supabase-auth/ (written to e-kancelaria/ due to FUSE lock)

output "project_ref" {
  description = "Configured Supabase project reference"
  value       = module.auth_config.project_ref
}

output "site_url" {
  description = "Configured site_url"
  value       = module.auth_config.site_url
}

output "redirect_urls" {
  description = "All configured redirect URLs"
  value       = module.auth_config.redirect_urls
}

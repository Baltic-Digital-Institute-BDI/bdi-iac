##############################################################################
# BDI Terraform Module — Supabase Project Outputs
##############################################################################

output "project_id" {
  description = "Supabase project ID"
  value       = supabase_project.this.id
}

output "api_url" {
  description = "Supabase API URL"
  value       = "https://${supabase_project.this.id}.supabase.co"
}

output "anon_key" {
  description = "Supabase anonymous key (retrieved via Supabase API, not TF-managed)"
  value       = "" # Placeholder: supabase provider does not export anon_key attribute
  sensitive   = true
}

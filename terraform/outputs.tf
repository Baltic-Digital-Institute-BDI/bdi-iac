##############################################################################
# BDI Terraform — Root Outputs
##############################################################################

output "vercel_project_id" {
  description = "Vercel project ID"
  value       = module.vercel_project.project_id
}

output "vercel_url" {
  description = "Vercel deployment URL"
  value       = module.vercel_project.url
}

output "vercel_domains" {
  description = "Vercel project domains"
  value       = module.vercel_project.domains
}

output "supabase_project_id" {
  description = "Supabase project ID"
  value       = module.supabase_project.project_id
}

output "supabase_api_url" {
  description = "Supabase API URL"
  value       = module.supabase_project.api_url
}

output "supabase_anon_key" {
  description = "Supabase anon key"
  value       = module.supabase_project.anon_key
  sensitive   = true
}

output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "resource_prefix" {
  description = "Resource naming prefix"
  value       = local.resource_prefix
}

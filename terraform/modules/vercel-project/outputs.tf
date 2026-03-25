##############################################################################
# BDI Terraform Module — Vercel Project Outputs
##############################################################################

output "project_id" {
  description = "Vercel project ID"
  value       = vercel_project.this.id
}

output "url" {
  description = "Vercel deployment URL"
  value       = "https://${vercel_project.this.name}.vercel.app"
}

output "domains" {
  description = "Custom domains attached to project"
  value       = [for d in vercel_project_domain.custom : d.domain]
}

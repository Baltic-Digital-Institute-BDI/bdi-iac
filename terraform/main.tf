##############################################################################
# BDI Lab Console — Infrastructure as Code
# Standard: BDI-IaC-Convention v1.0
#
# Manages: Vercel project + Supabase project
# Environments: dev, prod (via tfvars)
##############################################################################

locals {
  # BDI naming convention: {project}-{environment}
  resource_prefix = "${var.project_name}-${var.environment}"

  # Common tags/labels for resource identification
  common_tags = {
    project    = var.project_name
    environment = var.environment
    managed_by = "terraform"
    owner      = "bdi"
  }
}

# ─── Vercel Project ───────────────────────────────────────────────────────────

module "vercel_project" {
  source = "./modules/vercel-project"

  project_name = local.resource_prefix
  git_repository = var.vercel_git_repo
  team_id = var.vercel_team_id
  environment = var.environment
  framework = "nextjs"

  environment_variables = {
    NEXT_PUBLIC_SUPABASE_URL = module.supabase_project.api_url
    NEXT_PUBLIC_SUPABASE_ANON_KEY = module.supabase_project.anon_key
  }

  custom_domain = var.custom_domain
}

# ─── Supabase Project ─────────────────────────────────────────────────────────

module "supabase_project" {
  source = "./modules/supabase-project"

  project_name = local.resource_prefix
  organization_id = var.supabase_organization_id
  region = var.supabase_region
  database_password = var.supabase_database_password
  environment = var.environment
}

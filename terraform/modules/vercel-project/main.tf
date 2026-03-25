##############################################################################
# BDI Terraform Module — Vercel Project
# Standard: BDI-IaC-Convention v1.0 | IAC-01, IAC-04
##############################################################################

resource "vercel_project" "this" {
  name      = var.project_name
  framework = var.framework
  team_id   = var.team_id

  git_repository = {
    type = "github"
    repo = var.git_repository
  }

  build_command     = var.build_command
  output_directory  = var.output_directory
}

# ─── Environment Variables ───────────────────────────────────────────────────

resource "vercel_project_environment_variable" "vars" {
  for_each = var.environment_variables

  project_id = vercel_project.this.id
  team_id    = var.team_id
  key        = each.key
  value      = each.value
  target     = var.environment == "prod" ? ["production"] : ["preview", "development"]
}

# ─── Custom Domain (optional) ────────────────────────────────────────────────

resource "vercel_project_domain" "custom" {
  count = var.custom_domain != "" ? 1 : 0

  project_id = vercel_project.this.id
  team_id    = var.team_id
  domain     = var.custom_domain
}

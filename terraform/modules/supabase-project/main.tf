##############################################################################
# BDI Terraform Module — Supabase Project
# Standard: BDI-IaC-Convention v1.0 | IAC-01, IAC-04
##############################################################################

resource "supabase_project" "this" {
  organization_id   = var.organization_id
  name              = var.project_name
  database_password = var.database_password
  region            = var.region

  lifecycle {
    ignore_changes = [database_password]
  }
}

##############################################################################
# BDI Terraform — Provider Configuration
# Standard: BDI-IaC-Convention v1.0
##############################################################################

provider "vercel" {
  api_token = var.vercel_api_token
  team      = var.vercel_team_id
}

provider "supabase" {
  access_token = var.supabase_access_token
}

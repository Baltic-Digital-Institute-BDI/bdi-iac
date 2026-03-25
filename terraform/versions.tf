##############################################################################
# BDI Terraform — Version Constraints
# Standard: BDI-IaC-Convention v1.0
##############################################################################

terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    vercel = {
      source  = "vercel/vercel"
      version = "~> 2.0"
    }
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
  }
}

##############################################################################
# BDI Terraform — Root Variables
# Standard: BDI-IaC-Convention v1.0
##############################################################################

# ─── Environment ──────────────────────────────────────────────────────────────

variable "environment" {
  description = "Deployment environment (dev | prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

variable "project_name" {
  description = "BDI project name used for resource naming"
  type        = string
  default     = "bdi-lab-console"
}

# ─── Vercel ───────────────────────────────────────────────────────────────────

variable "vercel_api_token" {
  description = "Vercel API token (sensitive)"
  type        = string
  sensitive   = true
}

variable "vercel_team_id" {
  description = "Vercel Team ID"
  type        = string
}

variable "vercel_git_repo" {
  description = "GitHub repository for Vercel project (org/repo)"
  type        = string
  default     = "Baltic-Digital-Institute-BDI/bdi-lab-console"
}

# ─── Supabase ─────────────────────────────────────────────────────────────────

variable "supabase_access_token" {
  description = "Supabase Management API access token (sensitive)"
  type        = string
  sensitive   = true
}

variable "supabase_organization_id" {
  description = "Supabase organization ID"
  type        = string
}

variable "supabase_region" {
  description = "Supabase project region"
  type        = string
  default     = "eu-central-1"
}

variable "supabase_database_password" {
  description = "Supabase database password (sensitive)"
  type        = string
  sensitive   = true
}

# ─── Application ──────────────────────────────────────────────────────────────

variable "custom_domain" {
  description = "Custom domain for the application (optional)"
  type        = string
  default     = ""
}

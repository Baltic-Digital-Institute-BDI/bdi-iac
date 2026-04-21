# Target: bdi-iac/terraform/integrations/eka-supabase-auth/ (written to e-kancelaria/ due to FUSE lock)

# EKA-AUTH: Supabase Auth URL Config + OAuth Providers

variable "env" {
  type        = string
  description = "Environment: dev, test, prod"
}

variable "supabase_project_ref" {
  type        = string
  description = "Supabase project reference ID"
}

variable "site_url" {
  type        = string
  description = "Default redirect URL (site_url) for this environment"
}

variable "all_redirect_urls" {
  type        = list(string)
  description = "ALL allowed redirect URLs for this Supabase project (ALL products combined)"
}

variable "disable_signup" {
  type        = bool
  description = "Disable self-registration"
  default     = true
}

# ─── Google OAuth ────────────────────────────────────────────────────────────

variable "google_enabled" {
  type        = bool
  description = "Enable Google OAuth"
  default     = true
}

variable "google_client_id" {
  type        = string
  description = "Google OAuth 2.0 Client ID"
}

variable "google_secret" {
  type        = string
  description = "Google OAuth 2.0 Client Secret"
  sensitive   = true
}

# ─── Microsoft / Azure OAuth ────────────────────────────────────────────────

variable "azure_enabled" {
  type        = bool
  description = "Enable Microsoft Entra ID OAuth"
  default     = false
}

variable "azure_client_id" {
  type        = string
  description = "Microsoft OAuth Client ID"
  default     = ""
}

variable "azure_secret" {
  type        = string
  description = "Microsoft OAuth Client Secret"
  default     = ""
  sensitive   = true
}

variable "azure_url" {
  type        = string
  description = "Microsoft tenant URL"
  default     = ""
}

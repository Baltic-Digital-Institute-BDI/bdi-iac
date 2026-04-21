##############################################################################
# BDI Terraform Module — Supabase Auth Config Variables
##############################################################################

# ─── Core ────────────────────────────────────────────────────────────────────

variable "project_ref" {
  description = "Supabase project reference ID (e.g. vpbbguexygbqovsjfsab)"
  type        = string
}

variable "site_url" {
  description = "Default redirect URL after authentication (GOTRUE_SITE_URL)"
  type        = string
}

variable "redirect_urls" {
  description = "List of allowed redirect URLs (joined as comma-separated uri_allow_list)"
  type        = list(string)
  default     = []
}

variable "disable_signup" {
  description = "Disable new user self-registration"
  type        = bool
  default     = false
}

# ─── Google OAuth ────────────────────────────────────────────────────────────

variable "google_enabled" {
  description = "Enable Google OAuth provider"
  type        = bool
  default     = false
}

variable "google_client_id" {
  description = "Google OAuth 2.0 Client ID"
  type        = string
  default     = ""
}

variable "google_secret" {
  description = "Google OAuth 2.0 Client Secret"
  type        = string
  default     = ""
  sensitive   = true
}

# ─── Microsoft / Azure OAuth ────────────────────────────────────────────────

variable "azure_enabled" {
  description = "Enable Microsoft (Azure AD / Entra ID) OAuth provider"
  type        = bool
  default     = false
}

variable "azure_client_id" {
  description = "Microsoft OAuth Client ID"
  type        = string
  default     = ""
}

variable "azure_secret" {
  description = "Microsoft OAuth Client Secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_url" {
  description = "Microsoft tenant-specific URL (e.g. https://login.microsoftonline.com/<tenant-id>/v2.0)"
  type        = string
  default     = ""
}

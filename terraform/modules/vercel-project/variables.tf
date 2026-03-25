##############################################################################
# BDI Terraform Module — Vercel Project Variables
##############################################################################

variable "project_name" {
  description = "Vercel project name"
  type        = string
}

variable "git_repository" {
  description = "GitHub repository (org/repo format)"
  type        = string
}

variable "team_id" {
  description = "Vercel Team ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev | prod)"
  type        = string
}

variable "framework" {
  description = "Framework preset for Vercel"
  type        = string
  default     = "nextjs"
}

variable "build_command" {
  description = "Custom build command (optional)"
  type        = string
  default     = null
}

variable "output_directory" {
  description = "Custom output directory (optional)"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Map of environment variables to set"
  type        = map(string)
  default     = {}
}

variable "custom_domain" {
  description = "Custom domain to attach (optional)"
  type        = string
  default     = ""
}

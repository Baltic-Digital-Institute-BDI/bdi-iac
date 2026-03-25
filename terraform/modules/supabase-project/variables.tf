##############################################################################
# BDI Terraform Module — Supabase Project Variables
##############################################################################

variable "project_name" {
  description = "Supabase project name"
  type        = string
}

variable "organization_id" {
  description = "Supabase organization ID"
  type        = string
}

variable "region" {
  description = "Supabase project region"
  type        = string
  default     = "eu-central-1"
}

variable "database_password" {
  description = "Database password (sensitive)"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Deployment environment (dev | prod)"
  type        = string
}

# HIGH-014 W8.02 Identity-as-Code — GCP IAM Layer
# Created: 2026-04-09 by Claude agent
# Status: TEMPLATE — requires `gcloud` discovery to populate actual resource IDs
#
# Run discover-iam.sh on a machine with gcloud access to:
# 1. List all service accounts → populate google_service_account resources
# 2. List IAM bindings → populate google_secret_manager_secret_iam_member resources
# 3. terraform import each discovered resource
#
# Backend: same GCS bucket as secrets.tf (bdi-terraform-state)

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Uncomment after first successful plan from CI/CD or local machine with GCS access
  # backend "gcs" {
  #   bucket = "bdi-terraform-state"
  #   prefix = "gcp-iam"
  # }
}

provider "google" {
  project = "bdi-infrastructure"
  region  = "europe-west1"
}

# ──────────────────────────────────────────────
# Variables
# ──────────────────────────────────────────────

variable "project_id" {
  type    = string
  default = "bdi-infrastructure"
}

# Canonical BDI roles mapped to GCP secret access
variable "secret_access_matrix" {
  description = "Map of service account → list of secrets it can access"
  type        = map(list(string))
  default     = {}
  # Populated by discover-iam.sh output
  # Example:
  # {
  #   "agent-claude" = ["anthropic-api-key", "github-pat-agent-recovery"]
  #   "console-prod" = ["supabase-url", "supabase-anon-key", "google-oauth-client-id"]
  # }
}

# ──────────────────────────────────────────────
# Service Accounts — partially discovered
# ──────────────────────────────────────────────
# Discovery via REST API confirmed 1 SA. Full discovery requires
# roles/iam.securityReviewer on the SA running discover-iam.sh.
# sa-claude-agent has only secretmanager.versions.access (correct: least privilege).
#
# Known SA (from Supabase Vault bootstrap key):

resource "google_service_account" "agent_claude" {
  account_id   = "sa-claude-agent"
  display_name = "Claude Agent Service Account"
  description  = "Used by Claude Cowork/Code for secret access and automation"
  project      = var.project_id
}

# TODO: Run discover-iam.sh with a higher-privileged SA to find remaining SAs.
# Expected SAs (from secrets topology): console-prod, console-dev, vercel-deploy, n8n-worker

# ──────────────────────────────────────────────
# IAM Bindings — Secret Manager access per SA
# ──────────────────────────────────────────────
# Known binding: sa-claude-agent → bootstrap secrets (3)

resource "google_secret_manager_secret_iam_member" "agent_claude_gcp_sa_key" {
  project   = var.project_id
  secret_id = "bootstrap-gcp-sa-key-agent-claude"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.agent_claude.email}"
}

resource "google_secret_manager_secret_iam_member" "agent_claude_github_pat" {
  project   = var.project_id
  secret_id = "bootstrap-github-pat-agent-recovery"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.agent_claude.email}"
}

resource "google_secret_manager_secret_iam_member" "agent_claude_cf_token" {
  project   = var.project_id
  secret_id = "bootstrap-cf-api-token-dns-dr"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.agent_claude.email}"
}

# TODO: After full discovery, add remaining bindings for other SAs.

# ──────────────────────────────────────────────
# Outputs
# ──────────────────────────────────────────────

output "managed_service_accounts" {
  description = "List of TF-managed service accounts"
  value       = [google_service_account.agent_claude.email]
}

output "managed_iam_bindings" {
  description = "Count of TF-managed secret IAM bindings"
  value       = 3
}

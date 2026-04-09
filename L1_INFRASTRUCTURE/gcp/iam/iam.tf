# =============================================================================
# BDI Infrastructure — IAM-as-Code (W8.02 Identity-as-Code)
# HIGH-014 Everything-as-Code
# Generated: 2026-04-09 from live GCP discovery (securityReviewer)
# SSOT: dependency-dag.yaml W8.02 + ADR-014
# =============================================================================
#
# Two layers:
#   1. Project-level IAM bindings (this file)
#   2. Per-secret IAM bindings (secret_iam.tf)
#
# Per-secret bindings follow least-privilege:
#   sa-console-{env} gets secretAccessor ONLY on {env}-console-* secrets.
#
# Audit config: ADMIN_READ + DATA_READ + DATA_WRITE on secretmanager
# =============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "bdi-infrastructure-tfstate"
    prefix = "iam"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ─── Variables ───────────────────────────────────────────────────────────────

variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "bdi-infrastructure"
}

variable "region" {
  description = "Default GCP region"
  type        = string
  default     = "europe-west1"
}

variable "project_number" {
  description = "GCP project number"
  type        = string
  default     = "706500299685"
}

# ─── Service Accounts (7 custom) ────────────────────────────────────────────
# GCP-managed service agents (artifactregistry, cloudbuild, etc.) are NOT
# managed in TF — they're auto-created and auto-bound by Google.

resource "google_service_account" "sa_claude_agent" {
  account_id   = "sa-claude-agent"
  display_name = "Claude Agent (HIGH-013 W6.09 bootstrap DR)"
  description  = "Bootstrap SA for Claude agent DR fallback. Created 2026-04-08 closing W3.01 gap."
  project      = var.project_id
}

resource "google_service_account" "sa_bdi_agent" {
  account_id   = "sa-bdi-agent"
  display_name = "sa-bdi-agent"
  description  = "Machine identity for BDI agent automation (IDP Infrastructure Program)"
  project      = var.project_id
}

resource "google_service_account" "sa_gha_cicd_deployer" {
  account_id   = "sa-gha-cicd-deployer"
  display_name = "GitHub Actions CI/CD Deployer"
  description  = "HIGH-013 WIF target SA for GHA OIDC deployments from Baltic-Digital-Institute-BDI org"
  project      = var.project_id
}

resource "google_service_account" "sa_monitoring_deploy" {
  account_id   = "sa-monitoring-deploy"
  display_name = "sa-monitoring-deploy"
  project      = var.project_id
}

resource "google_service_account" "sa_console_prod" {
  account_id   = "sa-console-prod"
  display_name = "BDI Lab Console Secrets [prod]"
  description  = "Service account for GCP Secret Manager access (prod)"
  project      = var.project_id
}

resource "google_service_account" "sa_console_staging" {
  account_id   = "sa-console-staging"
  display_name = "BDI Lab Console Secrets [staging]"
  description  = "Service account for GCP Secret Manager access (staging)"
  project      = var.project_id
}

resource "google_service_account" "sa_console_dev" {
  account_id   = "sa-console-dev"
  display_name = "BDI Lab Console Secrets [dev]"
  description  = "Service account for GCP Secret Manager access (dev)"
  project      = var.project_id
}

# ─── Project-Level IAM Bindings ─────────────────────────────────────────────
# Using google_project_iam_member (additive) to avoid clobbering
# GCP-managed service agent bindings.

# --- sa-claude-agent (2 roles) ---
resource "google_project_iam_member" "claude_agent_security_reviewer" {
  project = var.project_id
  role    = "roles/iam.securityReviewer"
  member  = "serviceAccount:${google_service_account.sa_claude_agent.email}"
}

resource "google_project_iam_member" "claude_agent_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.sa_claude_agent.email}"
}

# --- sa-bdi-agent (1 role) ---
resource "google_project_iam_member" "bdi_agent_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.sa_bdi_agent.email}"
}

# --- sa-gha-cicd-deployer (5 roles) ---
resource "google_project_iam_member" "gha_deployer_cloudfunctions" {
  project = var.project_id
  role    = "roles/cloudfunctions.developer"
  member  = "serviceAccount:${google_service_account.sa_gha_cicd_deployer.email}"
}

resource "google_project_iam_member" "gha_deployer_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.sa_gha_cicd_deployer.email}"
}

resource "google_project_iam_member" "gha_deployer_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.sa_gha_cicd_deployer.email}"
}

resource "google_project_iam_member" "gha_deployer_secret_admin" {
  project = var.project_id
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:${google_service_account.sa_gha_cicd_deployer.email}"
}

resource "google_project_iam_member" "gha_deployer_storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.sa_gha_cicd_deployer.email}"
}

# --- sa-monitoring-deploy (1 role) ---
# NOTE: roles/owner is overly broad — consider scoping down post-audit
resource "google_project_iam_member" "monitoring_deploy_owner" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.sa_monitoring_deploy.email}"
}

# --- Default Compute SA (GCP-managed, project-level bindings only) ---
resource "google_project_iam_member" "compute_sa_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "compute_sa_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "compute_sa_cloudbuild_builder" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "compute_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "compute_sa_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

# --- Cloud Build SA (GCP-managed, project-level bindings only) ---
resource "google_project_iam_member" "cloudbuild_sa_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_sa_builder" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_sa_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_sa_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

# --- KR owner binding ---
resource "google_project_iam_member" "kr_owner" {
  project = var.project_id
  role    = "roles/owner"
  member  = "user:krzysztof@baltic-digital.org"
}

# ─── Audit Log Config ───────────────────────────────────────────────────────

resource "google_project_iam_audit_config" "secretmanager_audit" {
  project = var.project_id
  service = "secretmanager.googleapis.com"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# ─── Outputs ─────────────────────────────────────────────────────────────────

output "managed_service_accounts" {
  description = "List of TF-managed service accounts"
  value = [
    google_service_account.sa_claude_agent.email,
    google_service_account.sa_bdi_agent.email,
    google_service_account.sa_gha_cicd_deployer.email,
    google_service_account.sa_monitoring_deploy.email,
    google_service_account.sa_console_prod.email,
    google_service_account.sa_console_staging.email,
    google_service_account.sa_console_dev.email,
  ]
}

output "project_iam_binding_count" {
  description = "Count of TF-managed project-level IAM bindings"
  value       = 19
}

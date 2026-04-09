#!/usr/bin/env bash
# =============================================================================
# HIGH-014 W8.02 — Terraform Import for GCP IAM Resources
# Generated: 2026-04-09 from live discovery
# Run from: L1_INFRASTRUCTURE/gcp/iam/
# Prereq: terraform init
# =============================================================================
set -euo pipefail

PROJECT="bdi-infrastructure"
PROJECT_NUM="706500299685"

echo "=== Importing 7 Service Accounts ==="

terraform import "google_service_account.sa_claude_agent" \
  "projects/${PROJECT}/serviceAccounts/sa-claude-agent@${PROJECT}.iam.gserviceaccount.com"

terraform import "google_service_account.sa_bdi_agent" \
  "projects/${PROJECT}/serviceAccounts/sa-bdi-agent@${PROJECT}.iam.gserviceaccount.com"

terraform import "google_service_account.sa_gha_cicd_deployer" \
  "projects/${PROJECT}/serviceAccounts/sa-gha-cicd-deployer@${PROJECT}.iam.gserviceaccount.com"

terraform import "google_service_account.sa_monitoring_deploy" \
  "projects/${PROJECT}/serviceAccounts/sa-monitoring-deploy@${PROJECT}.iam.gserviceaccount.com"

terraform import "google_service_account.sa_console_prod" \
  "projects/${PROJECT}/serviceAccounts/sa-console-prod@${PROJECT}.iam.gserviceaccount.com"

terraform import "google_service_account.sa_console_staging" \
  "projects/${PROJECT}/serviceAccounts/sa-console-staging@${PROJECT}.iam.gserviceaccount.com"

terraform import "google_service_account.sa_console_dev" \
  "projects/${PROJECT}/serviceAccounts/sa-console-dev@${PROJECT}.iam.gserviceaccount.com"

echo ""
echo "=== Importing 19 Project-Level IAM Bindings ==="

# sa-claude-agent
terraform import "google_project_iam_member.claude_agent_security_reviewer" \
  "${PROJECT} roles/iam.securityReviewer serviceAccount:sa-claude-agent@${PROJECT}.iam.gserviceaccount.com"

terraform import "google_project_iam_member.claude_agent_secret_accessor" \
  "${PROJECT} roles/secretmanager.secretAccessor serviceAccount:sa-claude-agent@${PROJECT}.iam.gserviceaccount.com"

# sa-bdi-agent
terraform import "google_project_iam_member.bdi_agent_secret_accessor" \
  "${PROJECT} roles/secretmanager.secretAccessor serviceAccount:sa-bdi-agent@${PROJECT}.iam.gserviceaccount.com"

# sa-gha-cicd-deployer
terraform import "google_project_iam_member.gha_deployer_cloudfunctions" \
  "${PROJECT} roles/cloudfunctions.developer serviceAccount:sa-gha-cicd-deployer@${PROJECT}.iam.gserviceaccount.com"

terraform import "google_project_iam_member.gha_deployer_token_creator" \
  "${PROJECT} roles/iam.serviceAccountTokenCreator serviceAccount:sa-gha-cicd-deployer@${PROJECT}.iam.gserviceaccount.com"

terraform import "google_project_iam_member.gha_deployer_run_admin" \
  "${PROJECT} roles/run.admin serviceAccount:sa-gha-cicd-deployer@${PROJECT}.iam.gserviceaccount.com"

terraform import "google_project_iam_member.gha_deployer_secret_admin" \
  "${PROJECT} roles/secretmanager.admin serviceAccount:sa-gha-cicd-deployer@${PROJECT}.iam.gserviceaccount.com"

terraform import "google_project_iam_member.gha_deployer_storage_admin" \
  "${PROJECT} roles/storage.objectAdmin serviceAccount:sa-gha-cicd-deployer@${PROJECT}.iam.gserviceaccount.com"

# sa-monitoring-deploy
terraform import "google_project_iam_member.monitoring_deploy_owner" \
  "${PROJECT} roles/owner serviceAccount:sa-monitoring-deploy@${PROJECT}.iam.gserviceaccount.com"

# Default Compute SA
terraform import "google_project_iam_member.compute_sa_secret_accessor" \
  "${PROJECT} roles/secretmanager.secretAccessor serviceAccount:${PROJECT_NUM}-compute@developer.gserviceaccount.com"

terraform import "google_project_iam_member.compute_sa_artifact_writer" \
  "${PROJECT} roles/artifactregistry.writer serviceAccount:${PROJECT_NUM}-compute@developer.gserviceaccount.com"

terraform import "google_project_iam_member.compute_sa_cloudbuild_builder" \
  "${PROJECT} roles/cloudbuild.builds.builder serviceAccount:${PROJECT_NUM}-compute@developer.gserviceaccount.com"

terraform import "google_project_iam_member.compute_sa_log_writer" \
  "${PROJECT} roles/logging.logWriter serviceAccount:${PROJECT_NUM}-compute@developer.gserviceaccount.com"

terraform import "google_project_iam_member.compute_sa_storage_viewer" \
  "${PROJECT} roles/storage.objectViewer serviceAccount:${PROJECT_NUM}-compute@developer.gserviceaccount.com"

# Cloud Build SA
terraform import "google_project_iam_member.cloudbuild_sa_artifact_writer" \
  "${PROJECT} roles/artifactregistry.writer serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com"

terraform import "google_project_iam_member.cloudbuild_sa_builder" \
  "${PROJECT} roles/cloudbuild.builds.builder serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com"

terraform import "google_project_iam_member.cloudbuild_sa_account_user" \
  "${PROJECT} roles/iam.serviceAccountUser serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com"

terraform import "google_project_iam_member.cloudbuild_sa_run_admin" \
  "${PROJECT} roles/run.admin serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com"

# KR owner
terraform import "google_project_iam_member.kr_owner" \
  "${PROJECT} roles/owner user:krzysztof@baltic-digital.org"

echo ""
echo "=== Importing Audit Config ==="
terraform import "google_project_iam_audit_config.secretmanager_audit" \
  "${PROJECT} secretmanager.googleapis.com"

echo ""
echo "=== Importing 32 Per-Secret IAM Bindings ==="

# Dev secrets
for secret in \
  dev-console-anthropic-api-key \
  dev-console-n8n-api-key \
  dev-console-openai-api-key \
  dev-console-supabase-anon-key \
  dev-console-supabase-db-connection-string \
  dev-console-supabase-publishable-key \
  dev-console-supabase-url; do
  terraform import "google_secret_manager_secret_iam_member.dev_console[\"${secret}\"]" \
    "projects/${PROJECT}/secrets/${secret} roles/secretmanager.secretAccessor serviceAccount:sa-console-dev@${PROJECT}.iam.gserviceaccount.com"
done

# Staging secrets
for secret in \
  staging-console-anthropic-api-key \
  staging-console-n8n-api-key \
  staging-console-openai-api-key \
  staging-console-supabase-anon-key \
  staging-console-supabase-db-connection-string \
  staging-console-supabase-publishable-key \
  staging-console-supabase-url; do
  terraform import "google_secret_manager_secret_iam_member.staging_console[\"${secret}\"]" \
    "projects/${PROJECT}/secrets/${secret} roles/secretmanager.secretAccessor serviceAccount:sa-console-staging@${PROJECT}.iam.gserviceaccount.com"
done

# Prod secrets
for secret in \
  prod-console-anthropic-api-key \
  prod-console-cf-access-client-id \
  prod-console-cf-access-client-secret \
  prod-console-clickup-api-token \
  prod-console-n8n-api-key \
  prod-console-n8n-api-url \
  prod-console-n8n-gmail-oauth \
  prod-console-n8n-google-drive-oauth \
  prod-console-n8n-ms-teams-oauth \
  prod-console-n8n-supabase-api-key \
  prod-console-n8n-zoho-crm-oauth \
  prod-console-openai-api-key \
  prod-console-supabase-anon-key \
  prod-console-supabase-db-connection-string \
  prod-console-supabase-db-password \
  prod-console-supabase-publishable-key \
  prod-console-supabase-service-role-key \
  prod-console-supabase-url; do
  terraform import "google_secret_manager_secret_iam_member.prod_console[\"${secret}\"]" \
    "projects/${PROJECT}/secrets/${secret} roles/secretmanager.secretAccessor serviceAccount:sa-console-prod@${PROJECT}.iam.gserviceaccount.com"
done

echo ""
echo "=== Import Complete ==="
echo "Run 'terraform plan' to verify zero drift."

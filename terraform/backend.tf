##############################################################################
# BDI Terraform — Remote State Backend
# Standard: BDI-IaC-Convention v1.0
#
# Backend configured per-environment via -backend-config flag:
# terraform init -backend-config=environments/dev/backend.hcl
# terraform init -backend-config=environments/prod/backend.hcl
#
# IAC-02: Remote state with encryption + versioning
# DECISION: Cloudflare R2 (S3-compatible) — replaces AWS S3+DynamoDB
# NOTE: State locking deferred (single-operator, acceptable risk)
##############################################################################

terraform {
  backend "s3" {
    # Values injected from backend.hcl per environment
    # bucket = "bdi-terraform-state"
    # key = "lab-console/dev/terraform.tfstate"
    # region = "auto"
    # endpoints = { s3 = "https://<CF_ACCOUNT_ID>.r2.cloudflarestorage.com" }
    # skip_credentials_validation = true
    # skip_metadata_api_check = true
    # skip_requesting_account_id = true
    # skip_s3_checksum = true
  }
}

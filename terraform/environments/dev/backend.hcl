##############################################################################
# BDI Lab Console — DEV Backend Configuration
# Usage: terraform init -backend-config=environments/dev/backend.hcl
# Standard: IAC-02 (remote state)
# Backend: Cloudflare R2 (S3-compatible) — replaces AWS S3+DynamoDB
# State locking: deferred (single-operator, acceptable risk)
##############################################################################

bucket                      = "bdi-terraform-state"
key                         = "lab-console/dev/terraform.tfstate"
region                      = "auto"
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_requesting_account_id  = true
skip_s3_checksum            = true

endpoints = {
  s3 = "https://fefc776aadde11c617dd37567390a29e.r2.cloudflarestorage.com"
}

# EKA-AUTH — DEV environment
# Supabase project: bdi-dev (jiffxoseckvwlnskbuyk)
# SHARED with: Lab Console (dev-console.bdihub.pl)

env                  = "dev"
supabase_project_ref = "jiffxoseckvwlnskbuyk"

site_url = "https://dev-console.bdihub.pl"

# ALL redirect URLs — both products combined (FULL REPLACE)
# Verified against live config: 2026-04-22
all_redirect_urls = [
  # Lab Console (existing — DO NOT REMOVE)
  "https://dev-console.bdihub.pl/**",
  "https://console.bdihub.pl/**",
  # Legacy Vercel / other (existing — DO NOT REMOVE)
  "https://bdi-offer-grant-finance.vercel.app/**",
  "http://localhost:3000/**",
  # e-Kancelaria
  "https://dev.ekancelaria.bdi.technology/**",
]

disable_signup = false  # DEV: allow signup for testing

# Google OAuth
google_enabled   = true
google_client_id = "706500299685-a8ajtvu3rmatl3ds920k5hrh4krehtfv.apps.googleusercontent.com"
# google_secret → injected via TF_VAR_google_secret or CI pipeline

azure_enabled = false

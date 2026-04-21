# EKA-AUTH — PROD environment
# Supabase project: bdi-prod (vpbbguexygbqovsjfsab)
# SHARED with: Lab Console (console.bdihub.pl)

env                  = "prod"
supabase_project_ref = "vpbbguexygbqovsjfsab"

# site_url: Primary product for this Supabase project
# Keeping Lab Console as site_url to avoid breaking existing flows.
site_url = "https://console.bdihub.pl"

# ALL redirect URLs — both products combined (FULL REPLACE)
# Verified against live config: 2026-04-22
all_redirect_urls = [
  # Lab Console (existing — DO NOT REMOVE)
  "https://console.bdihub.pl/**",
  # Lab Console legacy Vercel previews (existing — DO NOT REMOVE)
  "https://bdi-lab-console.vercel.app/**",
  "https://bdi-lab-console-bdi.vercel.app/**",
  # e-Kancelaria
  "https://ekancelaria.bdi.technology/**",
]

disable_signup = true

# Google OAuth
google_enabled   = true
google_client_id = "706500299685-a8ajtvu3rmatl3ds920k5hrh4krehtfv.apps.googleusercontent.com"
# google_secret → injected via TF_VAR_google_secret or CI pipeline from GCP Secret Manager

# Microsoft OAuth — disabled for now (EKA-INT-011 not yet live)
azure_enabled = false

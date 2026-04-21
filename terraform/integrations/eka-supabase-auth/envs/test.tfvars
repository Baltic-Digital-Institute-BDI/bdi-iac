# EKA-AUTH — TEST environment
# Supabase project: bdi-test (adsdaehvvnwknjushshn)
# SHARED with: Lab Console (test-console.bdihub.pl)

env                  = "test"
supabase_project_ref = "adsdaehvvnwknjushshn"

site_url = "https://test-console.bdihub.pl"

# ALL redirect URLs — both products combined (additive)
all_redirect_urls = [
  # Lab Console (existing — DO NOT REMOVE)
  "https://test-console.bdihub.pl/**",
  "https://test-console.bdihub.pl/auth/callback",
  # e-Kancelaria (NEW)
  "https://test.ekancelaria.bdi.technology/**",
  "https://test.ekancelaria.bdi.technology/auth/callback",
]

disable_signup = true

# Google OAuth
google_enabled   = true
google_client_id = "706500299685-a8ajtvu3rmatl3ds920k5hrh4krehtfv.apps.googleusercontent.com"
# google_secret → injected via TF_VAR_google_secret or CI pipeline

azure_enabled = false

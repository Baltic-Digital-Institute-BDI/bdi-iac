# supabase-auth-config

BDI TIER 1 universal module for Supabase Auth configuration.

## What it manages

- `site_url` — default redirect after authentication
- `uri_allow_list` — allowed redirect URLs (all products combined)
- Google OAuth provider (enable + credentials)
- Microsoft/Azure OAuth provider (enable + credentials)
- `disable_signup` — self-registration toggle

## Usage

```hcl
module "auth_config" {
  source = "../modules/supabase-auth-config"

  project_ref = "vpbbguexygbqovsjfsab"
  site_url    = "https://console.bdihub.pl"

  redirect_urls = [
    "https://console.bdihub.pl/**",
    "https://ekancelaria.bdi.technology/**",
  ]

  google_enabled   = true
  google_client_id = "706500299685-xxx.apps.googleusercontent.com"
  google_secret    = var.google_secret  # from GCP SM / CI
}
```

## Apply per environment

```bash
terraform apply -var-file=envs/prod.tfvars -var="google_secret=$GOOGLE_SECRET"
terraform apply -var-file=envs/test.tfvars -var="google_secret=$GOOGLE_SECRET"
terraform apply -var-file=envs/dev.tfvars  -var="google_secret=$GOOGLE_SECRET"
```

## Provider requirements

```hcl
# In root module or provider config:
provider "supabase" {
  access_token = var.supabase_access_token  # env: SUPABASE_ACCESS_TOKEN
}
```

## CRITICAL: Shared Supabase Projects

BDI Supabase projects are SHARED across products (Lab Console, e-Kancelaria, etc.).
`uri_allow_list` is a FULL REPLACE — you must include ALL products' URLs in every apply.
The tfvars files in `envs/` contain the combined list per environment.

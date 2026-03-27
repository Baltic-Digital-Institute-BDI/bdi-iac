# S07 — Secrets Setup Guide

**Document ID:** S07-Secrets-Setup
**Version:** 1.0
**Date:** 2026-03-27
**Repo:** `Baltic-Digital-Institute-BDI/bdi-lab-console`

---

## BLUF

**12 GitHub Secrets** wymaganych przez ci.yml i promote.yml. Wszystkie skonfigurowane. Poniżej instrukcja setup/rotacji.

---

## 1. LOKALIZACJA

GitHub → `Baltic-Digital-Institute-BDI/bdi-lab-console` → **Settings** → **Secrets and variables** → **Actions**

---

## 2. LISTA SEKRETÓW

### 2.1 Vercel (3 sekrety)

| Secret | Wartość | Źródło |
|--------|---------|--------|
| `VERCEL_API_TOKEN` | Token API | Vercel Dashboard → Settings → Tokens → Create |
| `VERCEL_ORG_ID` | `team_ug381E6GRUIvq44iRBLlxTO9` | Vercel → Settings → General → Team ID |
| `VERCEL_PROJECT_ID` | `prj_FSaHU6bxrRl8cgqrzSqEIVHFy6uZ` | Vercel → Project → Settings → General → Project ID |

**Jak uzyskać VERCEL_API_TOKEN:**
1. Zaloguj się na https://vercel.com
2. Kliknij avatar → **Settings**
3. W menu bocznym → **Tokens**
4. **Create Token** → Scope: `Full Account` → Expiration: wg potrzeb
5. Skopiuj token → wklej do GitHub Secret

### 2.2 Supabase (4 sekrety)

| Secret | Wartość | Źródło |
|--------|---------|--------|
| `SUPABASE_ACCESS_TOKEN` | Personal access token | Supabase Dashboard → Account → Access Tokens |
| `SUPABASE_TEST_PROJECT_ID` | `mxssyiubrvbhcylglxzh` | Supabase → Project Settings → General |
| `SUPABASE_PROD_PROJECT_ID` | `vpbbguexygbqovsjfsab` | Supabase → Project Settings → General |
| `SUPABASE_TEST_DB_PASSWORD` | DB password | Supabase → Project Settings → Database → Password |

**Jak uzyskać SUPABASE_ACCESS_TOKEN:**
1. Zaloguj się na https://supabase.com/dashboard
2. Kliknij avatar → **Account preferences**
3. Sekcja **Access Tokens** → **Generate new token**
4. Nazwij token (np. `bdi-lab-console-ci`) → **Generate**
5. Skopiuj → wklej do GitHub Secret

### 2.3 Next.js Build (2 sekrety)

| Secret | Wartość | Źródło |
|--------|---------|--------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://jiffxoseckvwlnskbuyk.supabase.co` | Supabase → Project (bdi-dev) → Settings → API → URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | anon/public key | Supabase → Project (bdi-dev) → Settings → API → anon key |

**Uwaga:** Używamy **bdi-dev** project dla CI build (nie prod).

### 2.4 n8n (2 sekrety)

| Secret | Wartość | Źródło |
|--------|---------|--------|
| `N8N_PROD_BASE_URL` | `https://n8n-prod.bdihub.pl` | n8n instance URL |
| `N8N_PROD_API_KEY` | API key | n8n → Settings → API → Create API Key |

**Jak uzyskać N8N_PROD_API_KEY:**
1. Zaloguj się na https://n8n-prod.bdihub.pl
2. Kliknij **Settings** (ikona zębatki)
3. **API** → **Create API Key**
4. Skopiuj → wklej do GitHub Secret

### 2.5 Notifications (1 sekret)

| Secret | Wartość | Źródło |
|--------|---------|--------|
| `SLACK_WEBHOOK_URL` | Teams Incoming Webhook URL | Microsoft Teams → Channel → Connectors |

**Jak skonfigurować Teams Webhook:**
1. Microsoft Teams → wybierz kanał (np. `#ci-alerts`)
2. Kliknij `⋯` przy nazwie kanału → **Connectors**
3. Znajdź **Incoming Webhook** → **Configure**
4. Nazwa: `BDI CI/CD` → opcjonalnie ikona → **Create**
5. Skopiuj URL → wklej do GitHub Secret `SLACK_WEBHOOK_URL`

---

## 3. DODAWANIE/AKTUALIZACJA SEKRETU

**Krok po kroku:**

1. GitHub → `bdi-lab-console` → **Settings** (tab)
2. Menu boczne → **Secrets and variables** → **Actions**
3. Kliknij **New repository secret** (lub **Update** przy istniejącym)
4. **Name:** wpisz nazwę sekretu (np. `VERCEL_API_TOKEN`)
5. **Secret:** wklej wartość
6. Kliknij **Add secret**

---

## 4. ROTACJA SEKRETÓW

| Secret | Rekomendowana rotacja | Procedura |
|--------|----------------------|-----------|
| `VERCEL_API_TOKEN` | Co 90 dni | Vercel → revoke old → create new → update GitHub |
| `SUPABASE_ACCESS_TOKEN` | Co 90 dni | Supabase → revoke → generate new → update GitHub |
| `N8N_PROD_API_KEY` | Co 180 dni | n8n → delete old → create new → update GitHub |
| `SLACK_WEBHOOK_URL` | Przy zmianie kanału | Teams → nowy connector → update GitHub |
| Pozostałe | Przy zmianie infrastruktury | Wartości statyczne (project IDs, URLs) |

---

## 5. WERYFIKACJA

Po aktualizacji sekretów — uruchom pipeline manualnie:

1. GitHub → **Actions** → **CI/CD Pipeline** → **Run workflow**
2. Sprawdź czy wszystkie 5 jobów przechodzą
3. Jeśli `Deploy to Vercel` fail → sprawdź `VERCEL_API_TOKEN`
4. Jeśli `Build` fail → sprawdź `NEXT_PUBLIC_SUPABASE_URL` i `NEXT_PUBLIC_SUPABASE_ANON_KEY`

---

## 6. BEZPIECZEŃSTWO

- **Nigdy** nie commituj sekretów do kodu
- **Nigdy** nie loguj wartości sekretów w pipeline (GitHub maskuje je automatycznie)
- Sekrety są dostępne TYLKO w GitHub Actions runtime
- Fork'i **nie mają** dostępu do sekretów (zabezpieczenie GitHub)
- `CODEOWNERS` wymaga review od `@krzysztof-bdi` na każdym PR

---

**End of Secrets Setup Guide** | Generated: 2026-03-27 | Agent: Claude Opus 4.6 (Cowork)

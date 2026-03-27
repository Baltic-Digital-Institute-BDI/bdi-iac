# S07 — CI/CD Pipeline Runbook

**Document ID:** S07-CI-CD-Runbook
**Version:** 1.0
**Date:** 2026-03-27
**Repo:** `Baltic-Digital-Institute-BDI/bdi-lab-console`
**Maintainer:** @krzysztof-bdi

---

## 1. PIPELINE OVERVIEW

### ci.yml — Continuous Integration

**Trigger:** push na `main`, `develop`, `release/**` + PR na `main`, `develop` + `workflow_dispatch`

| Job | Zależność | Czas | Opis |
|-----|-----------|------|------|
| **Lint & Format Check** | — | ~31s | ESLint + Prettier |
| **Test Suite** | lint | ~26s | Vitest + coverage |
| **Build** | test | ~36s | Next.js build + artifact upload |
| **Deploy to Vercel** | build | ~45m | Vercel CLI `--prebuilt --prod` (tylko main push) |
| **Teams Notification** | all (always) | ~4s | Adaptive Card v1.4 |

### promote.yml — Promotion Pipeline

**Trigger:** `workflow_dispatch` z inputem `promotion_path`

| Path | Opis | Gate |
|------|------|------|
| `dev-to-test` | Promuje DEV → TEST | Confirmation `PROMOTE` |
| `test-to-prod` | Promuje TEST → PROD | Confirmation `PROMOTE` |
| `rollback-prod` | Rollback PROD do poprzedniego SHA | Confirmation `PROMOTE` |
| `rollback-test` | Rollback TEST do poprzedniego SHA | Confirmation `PROMOTE` |

---

## 2. URUCHOMIENIE PIPELINE

### 2.1 CI Pipeline (automatyczny)

Pipeline uruchamia się automatycznie na każdy push do `main`. Nie wymaga interwencji.

**Manual dispatch:**
1. GitHub → **Actions** → **CI/CD Pipeline** → **Run workflow**
2. Wybierz branch → **Run workflow**

### 2.2 Promotion (manual dispatch)

**Krok po kroku:**

1. GitHub → **Actions** → **Promote Environment**
2. Kliknij **Run workflow**
3. W polu `promotion_path` wpisz jedną z wartości:
   - `dev-to-test`
   - `test-to-prod`
   - `rollback-prod`
   - `rollback-test`
4. Kliknij **Run workflow**
5. Pipeline zapyta o potwierdzenie — wpisz `PROMOTE` w confirmation gate

### 2.3 Rollback

1. GitHub → **Actions** → **Promote Environment**
2. **Run workflow** z `promotion_path` = `rollback-prod` lub `rollback-test`
3. Potwierdź wpisując `PROMOTE`
4. Pipeline zredeploi poprzednią wersję z Vercel

---

## 3. TROUBLESHOOTING

### 3.1 Lint & Format Check fails

**Symptom:** Job `lint` czerwony, `Process completed with exit code 1/2`

**Diagnoza:**
- ESLint exit code 1 = błędy lint
- Prettier exit code 2 = pliki niesformatowane

**Fix:**
```bash
# ESLint — pokaż błędy
npx eslint . --max-warnings -1

# Prettier — autoformat
npx prettier --write src/

# Commit i push
git add -A && git commit -m "fix: lint/format issues" && git push
```

**Uwaga:** Oba stepy mają `continue-on-error: true` (transitional). Pipeline przejdzie mimo błędów lint/format.

### 3.2 Test Suite fails

**Symptom:** Job `test` czerwony

**Diagnoza:**
```bash
npm run test:ci
```

**Znane problemy:**
- 3 testy wyłączone w `vitest.config.ts` (`Badge.test.tsx`, `Card.test.tsx`, `types.test.ts`) — brak `@testing-library/dom`
- `continue-on-error: true` na test step (transitional)

**Fix:**
```bash
npm install -D @testing-library/dom @testing-library/react
# Napraw import w types.test.ts
# Usuń exclude z vitest.config.ts
```

### 3.3 Build fails

**Symptom:** Job `build` czerwony, `next build` error

**Częste przyczyny:**
1. **Brak Supabase env vars** → sprawdź GitHub Secrets: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`
2. **React infinite re-render** → sprawdź component powodujący loop (np. `/lab/bulk`)
3. **TypeScript errors** → `npx tsc --noEmit`

### 3.4 Deploy to Vercel fails

**Symptom:** Job `deploy-to-vercel` czerwony

**Diagnoza:**
1. Sprawdź logi — szukaj `Error:` w output
2. Sprawdź secret `VERCEL_API_TOKEN` — czy token ważny?
3. Sprawdź `VERCEL_ORG_ID` = `team_ug381E6GRUIvq44iRBLlxTO9`
4. Sprawdź `VERCEL_PROJECT_ID` = `prj_FSaHU6bxrRl8cgqrzSqEIVHFy6uZ`

**Fix:**
```bash
# Lokalny test
npx vercel --token=$VERCEL_API_TOKEN whoami
npx vercel deploy --prebuilt --prod --token=$VERCEL_API_TOKEN
```

### 3.5 Teams Notification nie przychodzi

**Symptom:** Job `notify` zielony, ale brak wiadomości w Teams

**Przyczyna:** `TEAMS_WEBHOOK_URL` secret jest placeholder lub pusty. Job jest guarded: `if: env.TEAMS_WEBHOOK_URL != ''`

**Fix:**
1. Teams → Channel → **Connectors** → **Incoming Webhook** → Create
2. Skopiuj URL
3. GitHub → **Settings** → **Secrets** → Update `SLACK_WEBHOOK_URL` z Teams URL

---

## 4. ENVIRONMENT MATRIX

| Env | Branch | Vercel Target | Supabase Project |
|-----|--------|--------------|------------------|
| **DEV** | `main` | dev alias | `jiffxoseckvwlnskbuyk` (bdi-dev) |
| **TEST** | promote | test alias | `mxssyiubrvbhcylglxzh` (bdi-test) |
| **PROD** | promote | production | `vpbbguexygbqovsjfsab` (bdi-prod) |

---

## 5. SEKRETY WYMAGANE

| Secret | Używany w | Opis |
|--------|-----------|------|
| `VERCEL_API_TOKEN` | ci.yml, promote.yml | Vercel deploy token |
| `VERCEL_ORG_ID` | ci.yml, promote.yml | Vercel team ID |
| `VERCEL_PROJECT_ID` | ci.yml, promote.yml | Vercel project ID |
| `NEXT_PUBLIC_SUPABASE_URL` | ci.yml (build) | Supabase endpoint dla Next.js |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | ci.yml (build) | Supabase anon key dla Next.js |
| `SUPABASE_ACCESS_TOKEN` | promote.yml | Supabase CLI auth |
| `SUPABASE_TEST_PROJECT_ID` | promote.yml | Supabase test project |
| `SUPABASE_PROD_PROJECT_ID` | promote.yml | Supabase prod project |
| `SUPABASE_TEST_DB_PASSWORD` | promote.yml | Supabase test DB |
| `N8N_PROD_API_KEY` | promote.yml | n8n API auth |
| `N8N_PROD_BASE_URL` | promote.yml | n8n endpoint |
| `SLACK_WEBHOOK_URL` | ci.yml, promote.yml | Teams Incoming Webhook URL |

---

## 6. KONTAKTY

| Rola | Osoba | Kontakt |
|------|-------|---------|
| **Pipeline Owner** | Krzysztof Rek | @krzysztof-bdi |
| **Vercel Admin** | Krzysztof Rek | Vercel Dashboard → BDI team |
| **Supabase Admin** | Krzysztof Rek | Supabase Dashboard |

---

**End of Runbook** | Generated: 2026-03-27 | Agent: Claude Opus 4.6 (Cowork)

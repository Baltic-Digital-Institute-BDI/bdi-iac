# n8n Workflows · Canonical Source

**SSOT** dla n8n workflow JSON definitions zarządzanych przez **A6 Fabric Owner** (BDI-STUDIO agent).
Per BDI-GOV-002 v3.1 §2 (Application code / IaC) + Infrastructure Master Map v1.5 D8 (`bdi-iac/n8n/workflows/`).

## Folder taxonomy

| File / Subfolder | Type | Owner | Notes |
|---|---|---|---|
| `EXPORTS_README.md` | Documentation | — | Legacy read-only backup convention (n8n Cloud exports 2026-03-25) |
| `F10-morning-priorities-reminder.json` | **Active source** | A6 Fabric | Cron `0 8 * * 1-5` Europe/Warsaw · Slack `#bdi-daily-priorities` |
| `F11-evening-closure-reminder.json` | **Active source** | A6 Fabric | Cron `30 16 * * 1-5` · Slack `#bdi-daily-closure` |
| `STU0-daily-OR.json` | **Active source** | A6 Fabric | Cron `0 11 * * 1-5` · Slack `#ws-bdi-studio` |
| `Friday-Weekly-Review.json` | **Active source** | A6 Fabric | Cron `0 14 * * 5` · Slack `#bdi-kr-digest` + Drive append |

## Authority chain

- **D-STU-082**: cron schedules ratified (2026-05-19)
- **D-STU-088**: W25-Q10 Track 3 (Slack integration n8n workflows)
- **D-STU-092**: cp_messages PROD LIVE (envelope INSERT dependency satisfied)
- **D-STU-102**: IaC canonicalization (this commit · 2026-05-19)
- **STU-AUDIT-GOV-002-001**: GOV-002 compliance audit identified Drive→GitHub migration (B.3 violation entry)

## Deploy procedure (A6 Fabric responsibility)

```bash
# 1. Import JSON do n8n via API
PAT=$(supabase-vault-get n8n_prod_api_key_agent)
curl -X POST https://n8n-prod.bdihub.pl/api/v1/workflows \
  -H "X-N8N-API-KEY: $PAT" \
  -H "Content-Type: application/json" \
  -d @F10-morning-priorities-reminder.json

# 2. Wire credentials (n8n UI · per node)
#    - supabase-prod-service-role
#    - slack-bdi-bot
#    - anthropic_api_key (REUSE prod-console-anthropic-api-key)
#    - google-drive-bdi-service (Friday Weekly Review only)

# 3. Manual test execution (UI) → verify cp_messages INSERT + Slack post
# 4. active:true (post passes)
```

**Workflow-specific test scenarios**: see `A6-FABRIC-DISPATCH-BRIEF.md` sekcja 3.2 (Drive workspace).

## Error handling

Wszystkie 4 workflows reference `wf-error-handler-cp-dlq` (errorWorkflow setting). A6 Fabric · deploy companion error handler workflow:

```
On any node error:
  1. INSERT do control_plane.cp_dlq (message_id NULL · failure_reason · failure_payload)
  2. Slack #bdi-observability if severity HIGH (retry_count > 3)
  3. n8n retry 3x exponential (5s · 25s · 125s) before DLQ
```

## Activation sequence (per A6 brief)

| Day | Action |
|---|---|
| **Day 0** (deploy) | All 4 deployed · credentials wired · test PASS · `active=false` |
| **Day 1** (Olga pilot kickoff) | Enroll Olga · activate F10 + F11 (`active=true`) |
| **Day 5+** (post-pilot) | Org-wide rollout decision · activate STU0 daily OR + Friday Weekly Review |

## Out of scope (Drive only · NOT in this canonicalization batch)

- `n8n-workflow-Friday-Weekly-Review-v2-with-KPIs.json` (next-iteration spec · pending KPI design)
- `n8n-workflow-Monthly-Review.json` (sprint-3 candidate · per A6 brief sekcja 7)

These remain in `BDI-STUDIO/_OUTPUTS/sub-agents/sprint-2/STU0-N8N-WORKFLOWS/` Drive working folder until next canonicalization batch.

## Change-log

| Date | Workflows added | Author |
|---|---|---|
| 2026-05-19 | F10 · F11 · STU0 Daily OR · Friday Weekly Review (4 active source) | STU-IAC-MIGRATE (CCS · sprint-2 day-2) |

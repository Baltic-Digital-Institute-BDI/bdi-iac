# Compliance Prompts · v1

**Status**: ACTIVE · bootstrap 2026-05-19 · D-STU-126 trigger · agent.specialist.CCS dispatch  
**Owner**: STU0 (capability supplier) · co-owner: agent.specialist.compliance (Mariusz · R-Compliance) + A5 Shield  
**Compliance**: BDI PI v4.1.6 sekcja 16 (BBC) · Contract Template v2.1 · AP-66 (NO-SCHEMA-FABRICATION)

## Purpose

Versioned, deterministic prompt library used by **agent.specialist.compliance** (cross-portfolio singleton · post-D-STU-126) and weekly automated compliance scans (Friday 06:00 PL · `0 6 * * 5`). Each prompt is a deterministic detection unit consumed by the orchestrator (Haiku/Sonnet model · prompt-injected with content fragment under test).

## 5 Categories

| Directory | Domain | Pattern count | Severity |
|-----------|--------|---------------|----------|
| `pii/` | GDPR personal data (PESEL · NIP · REGON · email · phone · address) | 6 | HIGH |
| `secrets/` | Credentials leak (API keys · OAuth · DB · GitHub PAT · CF tokens) | 5 | CRITICAL |
| `nis2/` | NIS2 directive controls (incident · risk · supply chain · crisis · timeline) | 5 | HIGH |
| `gdpr/` | GDPR controls (consent · retention · DPIA · DSR · cross-border) | 5 | HIGH |
| `iso17065/` | ISO/IEC 17065 cert body controls (impartiality · competence · complaints · docs · MS) | 5 | MEDIUM |

**Total**: 26 detection patterns · golden-set CI fixtures in `golden-set/`.

## File schema (per .yaml)

```yaml
name: <snake_case_id>                       # unique within v1/
category: <pii|secrets|nis2|gdpr|iso17065>
severity: <LOW|MEDIUM|HIGH|CRITICAL>
pattern_examples:                            # 3-5 sample inputs to illustrate
  - "..."
prompt_template: |                           # Claude-friendly system prompt
  ...                                        # MUST NOT echo secret material back
expected_output_schema:                      # JSON contract orchestrator expects
  detected: bool
  evidence: array<string>                    # redacted excerpts, never raw secrets
  sensitivity: <L0_PUBLIC|L1_INTERNAL|L2_CONFIDENTIAL|L3_SECRET|L4_RESTRICTED>
```

## CI gate semantics

GitHub Actions workflow `.github/workflows/compliance-prompts-ci.yml` (post-merge follow-up · NIE w tym PR) executes per-PR:

1. **Schema lint** · each .yaml validates against [meta-schema](./golden-set/_prompt_meta_schema.yaml) (yamllint + jsonschema)
2. **Golden-set replay** · orchestrator runs each prompt against `golden-set/<category>_positive.yaml` (must detect=true) and `golden-set/<category>_negative.yaml` (must detect=false)
3. **No secret leak gate** · grep-sweep verifies that `prompt_template` does NOT embed live secrets (PAT · OAuth tokens) · uses regex against vault-managed examples (substitutes `<REDACTED_*>` markers only)
4. **Versioning gate** · changes to `pii/` or `secrets/` require Mariusz + A5 + KR sign-off (CODEOWNERS · separate PR · added in post-merge follow-up)

CI fail = PR block · NIE auto-revert.

## Rollback

Per-prompt revert: `git revert <sha>` against branch + new PR. Library-level revert: bump version → `v0/` archive + `v1.1/` replacement (NIE in-place mutate · APPEND-ONLY semantyka per D-SYNC-3).

## Cross-references

- **Spec canonical**: `drive://BDI_DEV/L0_GOVERNANCE/AGENT-OS/PROJECT-WORKSPACES/BDI-STUDIO/_OUTPUTS/specs/COMPLIANCE-AGENT-AI_SPEC_v1.0.html` sekcja 4
- **A6 Fabric handshake**: `drive://BDI_DEV/L0_GOVERNANCE/AGENT-OS/HANDSHAKES/a6_fabric_compliance_prompts_v1_handshake.md`
- **Decision**: D-STU-126 (ratify · pending kr_prime sign-off)
- **Cadence**: BDI PI v4.1.6 sekcja 12 Tier 1/Tier 2 (Daily/Weekly) · sekcja 18 (F10/F11)
- **Envelope**: BDI PI v4.1.6 sekcja 10 (`control_plane.cp_messages` v1 · 18 pól)

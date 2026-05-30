# Golden-Set · CI Gate Fixtures

**Purpose**: deterministic test corpus used by CI workflow (post-merge follow-up · `.github/workflows/compliance-prompts-ci.yml`) to validate prompt detection accuracy on every PR touching `compliance-prompts/v1/`.

## Files

| File | Purpose |
|------|---------|
| `_prompt_meta_schema.yaml` | JSON Schema validating every `<category>/*.yaml` prompt |
| `_ci_replay_manifest.yaml` | Lists positive + negative sets and gate thresholds |
| `_expected_output_examples.yaml` | Sample orchestrator JSON outputs for documentation |
| `<category>_positive.yaml` | Inputs that MUST detect (`detected: true`) per category |
| `<category>_negative.yaml` | Inputs that MUST NOT detect (`detected: false`) per category |

## Gate semantics

- **Schema lint** — every `<category>/*.yaml` must validate against `_prompt_meta_schema.yaml`
- **Positive replay** — every case in `*_positive.yaml` must produce `detected: true` (gate threshold 100%)
- **Negative replay** — every case in `*_negative.yaml` must produce `detected: false` (gate threshold 0% false positive)
- **No-secret-leak** — grep-sweep verifies `prompt_template` does not embed live tokens (uses `<REDACTED_*>` placeholders only)
- **Versioning** — touching `pii/` or `secrets/` requires Mariusz + A5 + KR sign-off (CODEOWNERS post-merge)

## Adding a new test case

1. Add positive sample to `<category>_positive.yaml` with `expected.detected: true`
2. Add corresponding negative (false-positive guard) to `<category>_negative.yaml`
3. Run local replay (post-orchestrator setup) before opening PR
4. Update `_expected_output_examples.yaml` if shape changes

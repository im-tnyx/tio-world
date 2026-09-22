# TNYX-232 / GitHub #283 — Trusted Attribution Guard Live Validation

**Status:** In progress
**Primary owner:** repository governance (validation only; no guard/workflow/script ownership)
**Affected platforms:** None (documentation-only validation artifact; no Flutter/Supabase/product runtime change)

## Purpose

Clean live validation of the `Commit attribution guard` workflow (`.github/workflows/commit-attribution-guard.yml`) now landed on `main` via PR #310 (squash SHA `3ebe9f7c3a526abbaed5364c9db88054cfea03b9`). This PR exists only to prove, with real GitHub Actions evidence, that the trusted `pull_request_target` design actually runs from `main` and evaluates a PR without ever checking out or executing PR-controlled code.

## Non-Goals

- No product/runtime change (no Flutter/Supabase/app code).
- No modification to `.github/workflows/commit-attribution-guard.yml`.
- No modification to `scripts/check_commit_attribution.sh` or `scripts/check_commit_attribution_test.sh`.
- No branch-protection/ruleset configuration change.
- No deliberate prohibited AI attribution trailer in this pass — a deliberate FAIL/remediation test is a separate, explicitly authorized follow-up gate (it would likely require a feature-branch history rewrite / `--force-with-lease`, which needs its own authorization).
- No merge of this validation PR unless separately authorized.

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Documentation-only validation artifact; matches none of `AGENTS.md`'s three Owner Approval triggers.
**Explicit non-changes:** see Non-Goals above.

## Evidence

- GitHub #283 (open)
- Linear TNYX-232 (In Review)
- PR #310 (merged, squash SHA `3ebe9f7c3a526abbaed5364c9db88054cfea03b9`)
- `.ai/tasks/tnyx-232-ai-attribution-guard.md` — full guard implementation/correction history (G1-G4)

## Expected Result

The `Commit attribution guard` check runs on this PR using the `pull_request_target` event, checks out only `main`'s trusted code, fetches this PR's head as Git object data only, and reports SUCCESS (no prohibited AI attribution trailer present in this PR's own commits).

## Live Result

GitHub Actions run [35713989929](https://github.com/im-tnyx/tio-world/actions/runs/35713989929) — event `pull_request_target`, conclusion `SUCCESS`.

- `Checkout trusted base` → `git checkout ... 3ebe9f7c3a526abbaed5364c9db88054cfea03b9` (the merged base commit, not this PR's head).
- `Run fixture regression tests (trusted base code)` → `check_commit_attribution_test: 18 passed, 0 failed`.
- `Fetch PR head commit objects as data only` → `fetched PR #311 head eedccb9c4fdb09a4da23f9358ca3cdca9045ae38 as data only (not checked out, not executed)` — matches this PR's actual head SHA.
- `Check PR commits for prohibited AI attribution` → `Checking commit range 3ebe9f7c3a526abbaed5364c9db88054cfea03b9..eedccb9c4fdb09a4da23f9358ca3cdca9045ae38` → `no prohibited AI attribution found`.

This is direct log evidence (not inference) that the workflow definition and scripts executed came from trusted `main`, the working tree never left the base commit, and this PR's head was read only as Git object data.

A separate external check, `Code scanning AI findings on PR #311` (`github-advanced-security`), failed with the same `claude-opus-5` unsupported-model infrastructure error observed on PR #310 — not a repository code finding.

## Final Status

`In progress` — clean live-pass evidence collected and recorded. PR #311 left Draft/open, not merged. Deliberate FAIL/remediation validation is a separate, not-yet-authorized gate.

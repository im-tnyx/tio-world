# Pre-P9 — Coach current-state drift reconciliation

**Status:** Validated
**Completed:** 2026-09-27
**Date:** 2026-09-27
**Owner:** repository documentation governance + coaching
**Tracker:** GitHub #250 / Linear TNYX-193
**Base:** `main@4230849e36d23c64053108fcf4aac08a6f4cb664`

## Scope

Reconcile only the source-proven Coach current-state wording left open by the prior runtime-status audit.

### In scope
- `docs/screens/coach.md`: remove the stale claim that a fixed Tio/AI tab is currently visible runtime scaffolding.
- `docs/screens/README.md`: make the Coach catalog row reflect registered-branch vs guided-destination behavior.

### Verified evidence
- `shellBranchRegistry` registers `ShellTab.ai` at `/coach`.
- `AppDestination` has only Home, Workout, Nutrition, and Progress; no current App Mode guided destinations include Coach.
- `appModeRedirect()` redirects a disallowed shell branch such as `/coach` to an allowed destination after onboarding, and to onboarding before completion.
- `_shellBranchPage()` would use the shared `TioShellPlaceholder` for the AI branch if it were rendered.
- Linear TNYX-34 (AI coach orchestration pipeline) remains Backlog; no live Coach runtime is claimed.

## Explicit non-changes
- No Progress wording or implementation changes.
- No ROADMAP onboarding/App Mode cleanup in this slice.
- No runtime/UI/routes/state changes.
- No Supabase/backend/AI implementation.
- No GitHub #250 checkbox changes.
- Do not start or decide P9.

## Validation
- [x] Exact branch scope is task brief + two Coach canonical-doc surfaces.
- [x] Stale fixed-visible-tab wording is absent from the branch versions of the Coach docs.
- [x] Replacement wording matches current route policy and App Mode contracts.
- [x] Exact-head review/final gate completed.

## Validation Evidence

Repository API compare against `main@4230849e36d23c64053108fcf4aac08a6f4cb664` confirms the branch is 0 behind and the exact changed paths are this task brief, `docs/screens/README.md`, and `docs/screens/coach.md`. Branch content was re-read after the edits and matches `shellBranchRegistry`, `AppDestination.guidedDestinations`, and `appModeRedirect()` behavior. No runtime, Progress, backend, Supabase, #250 acceptance, or P9 files are in the diff.

## Known follow-up
`docs/planning/ROADMAP.md` still contains separate stale App Mode/onboarding current-state prose. Audit and reconcile it in its own bounded slice.

## Final Validation Verdict
`PASS`


## Merge Evidence

PR #436 was exact-head reviewed at `a4a1f43bc61d85be3e9470b6c7af77abbb5f93ce`. Manual review found no content findings, Codex reviewed the same commit and reported no major issues, unresolved review threads were 0, and the branch was 6 ahead / 0 behind its current `main` merge base. GitHub published no workflow/status checks for the docs-only head, so no CI-pass claim is made. PR #436 squash-merged as `12f0fcd3522b9d1f2344702d0371bd03d1cbf3ba`, verified as remote `main`. P9 remains not started.

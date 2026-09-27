# Pre-P9 — ROADMAP App Mode and onboarding drift reconciliation

**Status:** In progress
**Date:** 2026-09-27
**Owner:** repository documentation governance + product engineering planning
**Tracker:** GitHub #250 / Linear TNYX-193
**Base:** `main@7c3b3b3179ed83cd1a51f27723ca9f1c9bdfcff0`

## Scope

Reconcile only stale current-state prose in `docs/planning/ROADMAP.md` that contradicts implemented App Mode persistence and Product Onboarding state.

### Verified evidence
- D-021 records authenticated App Mode and `active_tabs` as canonical in `public.user_app_preferences`; local SharedPreferences is staging/cache.
- `SupabaseAppPreferencesRepository` is composed in app runtime and the screen catalog documents canonical restore/write behavior.
- Product Onboarding is implemented as one mode-conditional parent flow and current canonical docs describe the flow as implemented/frozen at its acceptance boundary.
- ROADMAP Phase 3 already marks the onboarding implementation/completion/persistence slices complete, so its App Mode introductory prose must not simultaneously call those same parts planned.

## In scope
- Replace the stale device-local-only App Mode ownership statement.
- Replace stale prose that calls Workout/Nutrition/Review/persistence/finish onboarding work planned.
- Preserve roadmap sequencing and all existing phase checkboxes.

## Explicit non-changes
- No runtime/UI/routing/state changes.
- No Supabase schema, migration, RLS, RPC, or data mutation.
- No Product Onboarding redesign or acceptance change.
- No Progress or Coach change.
- No GitHub #250 phase/acceptance checkbox change.
- Do not start or decide P9.

## Validation
- [x] Branch starts from fresh post-archive `main`.
- [x] Exact scope is this task brief plus `docs/planning/ROADMAP.md`.
- [x] Replacement wording agrees with D-021, current screen catalog, onboarding architecture, and runtime repository ownership.
- [x] Codex P2 findings incorporated: Account Setup/Product Onboarding entry boundary, completion-gated canonical persistence, and structural-vs-eligibility validation wording.
- [ ] Exact-head review/final gate completed.

## Final Validation Verdict
`REVIEW`

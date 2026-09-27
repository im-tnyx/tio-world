# Pre-P9 — Canonical runtime-status drift reconciliation

**Status:** In progress
**Date:** 2026-09-27
**Owner:** repository documentation governance
**Tracker:** GitHub #250 / Linear TNYX-193
**Base:** `main@ea114c06371955b983a6b8cb1eaf60cc57bb6d06`

## Scope

Reconcile only source-proven stale current-status wording found during the broader pre-P9 canonical contradiction audit.

### In scope
- `docs/screens/README.md`: stale Splash, Login, Home, and Workout current-status rows.
- `docs/mobile/FLUTTER_MODULAR_STRUCTURE.md`: stale onboarding “planned full flow” wording.

### Source evidence
- Splash delegates session resolution/destination routing to app-level bootstrap; `app_session_route_policy.dart` implements the redirect state policy.
- Auth composition uses Supabase session/sign-in repositories; `LoginPage` is wired to real auth use cases.
- App router acceptance coverage renders `HomePage` at Home.
- `WorkoutHomePage` is real runtime source with calendar + Library entry; shell routes ship Library and Exercises.
- Product Onboarding is implemented/frozen; current canonical onboarding docs and runtime/source already record the completed flow.

## Explicit non-changes
- Do not alter Progress or Coach status in this slice; their depth needs separate evidence.
- No runtime/UI/routes/state changes.
- No Supabase/schema/RLS/migration/function changes.
- No GitHub #250 checkbox changes.
- Do not start or decide P9.

## Validation
- [x] Only task brief + two canonical docs differ.
- [x] Target stale phrases are absent/replaced with bounded source-backed wording.
- [x] No runtime/Supabase/#250/P9 mutation.
- [ ] Exact-head PR review and final gate.

## Known limitation
This slice resolves only the proven runtime-status drift cluster. The broader canonical contradiction audit remains open, so GitHub #250 acceptance criterion “No canonical document contains a statement contradicted by the current checkout” must remain unchecked.

## Final Validation Verdict
`REVIEW`

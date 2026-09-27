# Archive

This folder keeps concise records of completed or superseded AI task briefs. It preserves decision context without letting old work appear active.

## What Belongs Here

- A task brief whose outcome is validated.
- A task brief superseded by a newer approved direction.
- A short retrospective only when it contains a durable lesson that cannot live in canonical documentation.

## What Does Not Belong Here

- Active work, open questions, or an unvalidated implementation.
- Full chat transcripts, terminal output, logs, generated artifacts, or temporary plans.
- Secrets, personal data, credentials, machine-specific paths, or copies of source code.

## Archive Procedure

1. Update the task status to `Validated` or `Superseded` and add the completion date.
2. Ensure durable product, architecture, or ownership decisions are recorded in canonical docs and, where useful, [DECISIONS.md](../DECISIONS.md).
3. Move the task brief here with a stable name: `YYYY-MM-topic.md`.
4. Add one row below with the archive date, outcome, and canonical reference.

## Archived Tasks

| Archived | Task | Outcome | Canonical reference |
|---|---|---|---|
| 2026-09-27 | [Pre-P9 — Product Onboarding task-index reconciliation](2026-09-pre-p9-onboarding-task-index-reconciliation.md) | Validated; stale O1/O1F current-sequencing claims reconciled and merged via PR #426 (`6ca53860`) | `.ai/tasks` orientation, GitHub #40 / #11 / #44, Linear TNYX-6, GitHub #250 / Linear TNYX-193 |
| 2026-09-27 | [Pre-P9 — Dynamic current-state snapshot refresh](2026-09-pre-p9-dynamic-snapshot-refresh.md) | Validated; refreshed both dynamic snapshots and merged via PR #424 (`069c9601`) | [.ai/CURRENT.md](../CURRENT.md), [.ai/IMPLEMENTATION_STATUS.md](../IMPLEMENTATION_STATUS.md), GitHub #250 / Linear TNYX-193 |
| 2026-09-27 | [Product Onboarding — Canonical Execution Plan](2026-09-product-onboarding-canonical-execution.md) | Superseded historical execution checkpoint; #40 complete/frozen and PR #50 merged | [ONBOARDING_ARCHITECTURE.md](../../docs/architecture/ONBOARDING_ARCHITECTURE.md), GitHub #40 / #44, merged PR #50 |
| 2026-09-27 | [TNYX-193 P7 — Dynamic current-state snapshots](2026-09-tnyx-193-p7-current-state-snapshots.md) | Validated; merged via PR #421 (`25d4dd08`) | [.ai/CURRENT.md](../CURRENT.md), [.ai/IMPLEMENTATION_STATUS.md](../IMPLEMENTATION_STATUS.md), GitHub #250 / Linear TNYX-193 |
| 2026-09-24 | [TNYX-78 W1A0 — Workout canonical identities and terminology](2026-09-tnyx-78-w1a0-workout-canonical-identities.md) | Validated; merged via PR #324 (`45c194e0`) | [ADR-0011](../../docs/adr/0011-workout-canonical-identities-and-exercise-catalog.md), D-019 in [DECISIONS.md](../DECISIONS.md) |
| 2026-09-24 | [TNYX-258 W1A7 — Stale shared Workout scaffold cleanup](2026-09-tnyx-258-w1a7-stale-workout-scaffold-cleanup.md) | Validated; merged via PR #327 (`ec1f94c9`) | [ADR-0011](../../docs/adr/0011-workout-canonical-identities-and-exercise-catalog.md), D-019 in [DECISIONS.md](../DECISIONS.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-24 | [TNYX-259 W1A1 — Canonical Workout identity value objects](2026-09-tnyx-259-w1a1-workout-identity-value-objects.md) | Validated; merged via PR #329 (`17de0500`) | D-019 in [DECISIONS.md](../DECISIONS.md), [ADR-0011](../../docs/adr/0011-workout-canonical-identities-and-exercise-catalog.md) |
| 2026-09-24 | [Workout Library / Exercises / Explore IA reconciliation](2026-09-workout-library-exercises-ia-reconciliation.md) | Validated; merged via PR #331 (`65353fec`) | D-020 in [DECISIONS.md](../DECISIONS.md), [Library](../../docs/screens/library.md) |
| 2026-09-24 | [TNYX-260 W1A2 — Canonical Exercise read model](2026-09-tnyx-260-w1a2-canonical-exercise-read-model.md) | Validated; merged via PR #333 (`a30c148e`) | D-019 in [DECISIONS.md](../DECISIONS.md), [ADR-0011](../../docs/adr/0011-workout-canonical-identities-and-exercise-catalog.md) |
| 2026-09-24 | [TNYX-269 W3A1 — Exercise catalog data foundation](2026-09-tnyx-269-w3a1-exercise-catalog-data-foundation.md) | Validated; merged via PR #335 (`8cd61a48`) | [ADR-0011](../../docs/adr/0011-workout-canonical-identities-and-exercise-catalog.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md), [Exercises and Exercise Picker](../../docs/screens/exercise-search.md) |
| 2026-09-25 | [TNYX-270 W3A2a — Exercise catalog content/source integration](2026-09-tnyx-270-w3a2a-exercise-catalog-content-integration.md) | Validated; merged via PR #339 (`a023730f`); TNYX-270 stays open for TNYX-274 (catalog media) and TNYX-272 (W3A2b) | [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md), [Exercises and Exercise Picker](../../docs/screens/exercise-search.md) |
| 2026-09-25 | [TNYX-273 W3A2a-F1 — Post-merge catalog review fixes](2026-09-tnyx-273-w3a2a-post-merge-review-fixes.md) | Validated; merged via PR #340 (`359e24ff`) | [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md), [Exercises and Exercise Picker](../../docs/screens/exercise-search.md) |
| 2026-09-25 | [TNYX-274 W3A2a-F2 — Exercise catalog media](2026-09-tnyx-274-w3a2a-f2-catalog-media.md) | Validated; merged via PR #343 (`bb2961eb`) | [Exercises and Exercise Picker](../../docs/screens/exercise-search.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-25 | [TNYX-272 W3A2b — Exercises screen & route](2026-09-tnyx-272-w3a2b-exercises-screen-route.md) | Validated; merged via PR #345 (`38fa740a`) | [Exercises and Exercise Picker](../../docs/screens/exercise-search.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-25 | [TNYX-266 W6A — Library route & capability-gated root](2026-09-tnyx-266-w6a-library-route.md) | Validated; merged via PR #349 (`a98bce82`) | [Library](../../docs/screens/library.md), [Exercises and Exercise Picker](../../docs/screens/exercise-search.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-25 | [Workout Exercises presentation Library relocation](2026-09-workout-exercises-library-presentation-relocation.md) | Validated; merged via PR #352 (`7f672f20`) | D-020 in [DECISIONS.md](../DECISIONS.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md), [Exercises and Exercise Picker](../../docs/screens/exercise-search.md) |
| 2026-09-26 | [#350 — Universal top-bar title gap (`TioAppBar`)](2026-09-issue-350-top-bar-title-gap.md) | Validated; merged via PR #354 (`03bb578a`) | [Core theme README — App bar and topbar](../../apps/core/lib/src/theme/README.md) |
| 2026-09-26 | [Workout Library push jerk](2026-09-workout-library-push-chrome-jerk.md) | Validated; merged via PR #355 (`bea89d16`) | [Library](../../docs/screens/library.md), [Exercises and Exercise Picker](../../docs/screens/exercise-search.md) |
| 2026-09-26 | [TNYX-271 — App startup path organization](2026-09-tnyx-271-app-startup-organization.md) | Validated; merged via PR #338 (`f5bf3c4f`) | [FLUTTER_MODULAR_STRUCTURE.md](../../docs/mobile/FLUTTER_MODULAR_STRUCTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 B1 — Runtime/Auth composition split](2026-09-tnyx-201-b1-runtime-auth-composition.md) | Validated; merged via PR #360 (`ad3f69e3`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 B2 — HydrationPreferences composition split](2026-09-tnyx-201-b2-hydration-preferences-composition.md) | Validated; merged via PR #363 (`05dd852b`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md), [ADR-0009](../../docs/adr/0009-settings-local-default-glass-size.md) |
| 2026-09-26 | [TNYX-201 B3 — Workout composition split](2026-09-tnyx-201-b3-workout-composition.md) | Validated; merged via PR #366 (`18413a40`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 B4 — Onboarding composition split](2026-09-tnyx-201-b4-onboarding-composition.md) | Validated; merged via PR #369 (`7d88a605`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 B5 — Nutrition composition split](2026-09-tnyx-201-b5-nutrition-composition.md) | Validated; merged via PR #372 (`b973676f`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 B6 — Body + Wellness composition split](2026-09-tnyx-201-b6-body-wellness-composition.md) | Validated; merged via PR #375 (`91e6758b`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 C1 — Router shell extraction](2026-09-tnyx-201-c1-router-shell.md) | Validated; merged via PR #378 (`85a14875`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 C2a — Auth route group extraction](2026-09-tnyx-201-c2a-auth-routes.md) | Validated; merged via PR #381 (`646d3e9a`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 C2b1 — Account Setup route extraction](2026-09-tnyx-201-c2b1-account-setup-routes.md) | Validated; merged via PR #384 (`c0d7c2e2`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 C2b2 — Product Onboarding route extraction](2026-09-tnyx-201-c2b2-onboarding-routes.md) | Validated; merged via PR #387 (`e458eda5`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 C3a — Settings route extraction](2026-09-tnyx-201-c3a-settings-routes.md) | Validated; merged via PR #390 (`31109dac`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 C3b — App Settings hub route extraction](2026-09-tnyx-201-c3b-app-settings-route.md) | Validated; merged via PR #393 (`42372448`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 C3c — Health & Goals hub route extraction](2026-09-tnyx-201-c3c-health-goals-hub-route.md) | Validated; merged via PR #396 (`8232a01d`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 C3d — Profile Settings route extraction](2026-09-tnyx-201-c3d-profile-settings-route.md) | Validated; merged via PR #399 (`9f8d9efc`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [TNYX-201 C3e — Nutrition navigation route extraction](2026-09-tnyx-201-c3e-nutrition-navigation-routes.md) | Validated; merged via PR #402 (`1bb41dd8`) | [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md) |
| 2026-09-26 | [GitHub #403 — Security-check governance](2026-09-issue-403-security-check-governance.md) | Validated; merged via PR #405 (`aede3c67`) | [AGENTS.md](../../AGENTS.md), [PUSH_TEMPLATE.md](../../.github/PUSH_TEMPLATE.md) |
| 2026-09-27 | [TNYX-193 P3 — Current-state documentation drift](2026-09-tnyx-193-p3-current-state-doc-drift.md) | Validated; merged via PR #408 (`a439c57f`) | [DEVELOPMENT_SETUP.md](../../docs/development/DEVELOPMENT_SETUP.md), [FLUTTER_MODULAR_STRUCTURE.md](../../docs/mobile/FLUTTER_MODULAR_STRUCTURE.md), [MODULE_OWNERSHIP.md](../../docs/architecture/MODULE_OWNERSHIP.md), [SUPABASE_STRATEGY.md](../../docs/data/SUPABASE_STRATEGY.md) |
| 2026-09-27 | [TNYX-193 P4 — Documentation authority governance](2026-09-tnyx-193-p4-doc-authority-governance.md) | Validated; merged via PR #410 (`ff211c40`) | [README.md](../../docs/README.md), [.ai/README.md](../README.md), [.ai/workflow.md](../workflow.md) |
| 2026-09-27 | [TNYX-193 P4A — Documentation location normalization](2026-09-tnyx-193-p4a-doc-location-normalization.md) | Validated; merged via PR #412 (`aa42e7f5`) | [Documentation layout](../../docs/README.md), [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md), [SUPABASE_STRATEGY.md](../../docs/data/SUPABASE_STRATEGY.md) |
| 2026-09-27 | [TNYX-193 P4B — Supabase public schema inventory](2026-09-tnyx-193-p4b-supabase-schema-inventory.md) | Validated; merged via PR #414 (`fdb946e8`) | [SUPABASE_SCHEMA.md](../../docs/data/SUPABASE_SCHEMA.md), [SUPABASE_STRATEGY.md](../../docs/data/SUPABASE_STRATEGY.md) |
| 2026-09-27 | [TNYX-193 P5 — Documentation governance header rollout](2026-09-tnyx-193-p5-doc-governance-headers.md) | Validated; merged via PR #417 (`44101359`) | [Documentation governance](../../docs/README.md), GitHub #250 / Linear TNYX-193 |
| 2026-09-27 | [TNYX-193 P6 — AI governance headers](2026-09-tnyx-193-p6-ai-governance-headers.md) | Validated; merged via PR #419 (`77547eb3`) | [Documentation governance](../../docs/README.md), [.ai/README.md](../README.md), GitHub #250 / Linear TNYX-193 |

| 2026-09-27 | [Pre-P9 — Post-index dynamic snapshot refresh](2026-09-pre-p9-snapshot-post-index-refresh.md) | Validated; snapshots reconciled and merged via PR #428 (`0db78d42`) | [.ai/CURRENT.md](../CURRENT.md), [.ai/IMPLEMENTATION_STATUS.md](../IMPLEMENTATION_STATUS.md), GitHub #250 / Linear TNYX-193 |

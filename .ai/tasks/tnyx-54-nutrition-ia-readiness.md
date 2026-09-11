# TNYX-54 — Nutrition IA / Domain Contract Readiness

> **Document Status:** Historical Snapshot
> **Snapshot date:** 2026-09-08
> **Later state:** TNYX-54 reached `Done` on 2026-09-08, after this snapshot was written.
> **Truth Boundary:** This file records only the repository, tracker and Supabase state observed on 2026-09-08. It is not authoritative for current repository, tracker or migration state. The HEAD SHA, issue statuses and migration count below are preserved exactly as written and are deliberately not updated. For current truth use the live repository source and configuration, `supabase/migrations/`, and Linear.

**Status:** Ready
**Primary owner:** `apps/features/nutrition` contract boundaries; `apps/app` composition; `apps/core` reusable UI and route contracts
**Affected platforms:** Flutter Android + iOS readiness documentation only

## Owner Approval and Scope Boundary

**Trigger:** None — read-only audit and focused task record
**Approval status:** Not required for this audit; a TNYX-54 Linear status transition still requires explicit owner approval
**Approval evidence:** 2026-09-08 owner-authorized TNYX-66 readiness refresh for TNYX-54
**Approved product/UI/data-shape boundaries:** Determine whether the existing TNYX-54 architecture/domain contract is sufficient to unblock a focused TNYX-68 readiness slice
**Explicit non-changes:** No production Flutter source/test, routing, Meal Diary Settings UI, Meal Categories UI, Quick Add Meal type activation, Meal Editor, MealLog persistence, Supabase mutation, status change, dependency change, Slice C, or Slice D

## Active Handoff

**Planning owner:** Codex `/root`
**Implementation owner:** None — no implementation is authorized or required
**Review owner:** None
**Implementation ownership state:** Not started
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-08
**Branch:** `main`
**HEAD SHA:** `9be00dcb1a3a8e3707a811a29f783dfd21c04d46`
**Observed working-tree state:** `main == origin/main`; the unrelated root `pubspec.lock` remains modified, plus this focused readiness brief
**Observed uncommitted/dirty files:** `pubspec.lock` SHA-256 `004DE1A093C1F04F684B39DF072C2F2E37B1CD21046BFEE01E628E7F77300B1C`; this task brief
**PR / tracker:** No open GitHub PR and no TNYX-54/TNYX-68/Slice C remote branch. TNYX-54/TNYX-66/TNYX-68 remain `Backlog`; TNYX-67 remains unexpectedly `Done` after PR #225 automation drift.
**Current implementation state:** TNYX-54 is a contract gate, not a requirement that every future Nutrition feature already exist
**Relevant execution surface:** Nutrition domain/data/presentation, Meal Diary/Meal Logging shells, Core calendar/routes/settings components, app routing/providers, current Linear contracts, hosted Supabase prerequisite
**Validation completed at SHA:** Read-only repo/GitHub/Linear/Supabase audit plus `git diff --check`
**Validation remaining:** Owner authorization before any TNYX-54 status transition; separate TNYX-68 readiness and visible shell approval
**Current blocker:** None inside the TNYX-54 architecture/domain contract
**Open review finding IDs:** None
**Next exact action:** Owner-authorized TNYX-54 status reconciliation, then a separate TNYX-68 minimal Meal Diary Settings shell readiness task

## 1. Audit Question

Is TNYX-54 sufficiently resolved as an architecture/domain contract to unblock TNYX-68 readiness, without requiring every future Nutrition feature to be implemented?

Result: **YES — READY.**

## 2. Acceptance Matrix

| # | TNYX-54 contract area | Result | Current evidence / boundary |
|---:|---|---|---|
| 1 | Meal Diary ownership | PASS | Nutrition owns `meal_diary/`; `/nutrition` renders `MealDiaryPage` while app owns shell composition. |
| 2 | Meal Logging ownership | PASS | Nutrition owns `meal_logging/` and the current Quick Add presentation shell; durable logging remains separately gated. |
| 3 | Saved Meals boundary | PASS | Explicit reusable-template contract; not actual history or planned identity; no speculative folder exists. |
| 4 | Overview/read-model boundary | PASS | Daily/meal summaries are derived read models, not authoritative duplicate storage. |
| 5 | Food Catalog boundary | PASS | Provider/catalog results are candidates/provenance, not MealLog or SavedMeal identity. |
| 6 | Diet Preferences ownership | PARTIALLY SATISFIED | Nutrition-specific profile data and repository are Nutrition-owned; the future `diet_preferences/` physical folder migration has not occurred and is not needed for TNYX-68 readiness. |
| 7 | Nutrition Targets ownership | PASS | Canonical target domain/repositories and Settings editors are Nutrition-owned; onboarding and Settings compose the same target contract. |
| 8 | Nutrition Schedule ownership | PASS | Contract separates schedule/eating strategy from canonical targets; runtime implementation remains a later slice. |
| 9 | Nutrition Settings grouping | PASS | Current `NutritionSettingsPage` is a launcher for implemented Nutrition capabilities and owns no duplicate domain data. |
| 10 | Meal Plans boundary | PASS | Future planned-meal/plan identity is explicit; no empty module was created. |
| 11 | Recipes boundary | PASS | Future reusable recipe identity is separate from actual consumed history. |
| 12 | Grocery boundary | PASS | Future shopping/list generation remains separate and unscaffolded. |
| 13 | Generic User Profile | PASS | Generic Profile remains app-global; Nutrition owns only dietary profile/context. |
| 14 | Actual/draft/template/plan identity | PASS | `MealLogEntry`, `MealLoggingDraft`, `SavedMeal`, and `PlannedMeal` semantics are explicitly distinct. |
| 15 | Quick Add coarse path | PASS | TNYX-158 supplies the no-save shell; TNYX-115 owns future first-class manual `MealLogEntry` lifecycle without fake items. |
| 16 | Recent repeat identity | PASS | Repeat snapshots into a new draft/new eventual log; it never edits or reuses the source log ID. |
| 17 | Meal note ownership | PASS | Note belongs to draft/actual meal event, not catalog truth; repeat defaults it empty and planned instructions remain separate. |
| 18 | Calendar ownership | PASS | `apps/core` owns `TioDateCalendar`; Nutrition owns selected-date/range state and app composition supplies global week start. |
| 19 | Units ownership | PASS | Units remain app/Settings-owned and are only consumed by Nutrition. |
| 20 | Target/schedule/daily budget | PASS | Canonical target, strategy schedule, and derived `DailyNutritionBudget(date)` are separate contracts. |
| 21 | Package/folder direction | PARTIALLY SATISFIED | Current source uses live `domain`, `data`, `presentation`, `meal_diary`, and `meal_logging` conventions; feature-first subfolders evolve only with real slices. |
| 22 | No speculative folders | PASS | No empty `saved_meals`, `overview`, `food_catalog`, `nutrition_schedule`, `meal_plans`, `recipes`, or `grocery` folders exist. |

The two partial items are physical organization follow-ups, not unresolved ownership decisions and not blockers for a minimal TNYX-68 shell.

## 3. Stale but Non-Blocking Documentation

- `.ai/CURRENT.md` remains an older Onboarding O7 snapshot.
- `docs/MODULE_OWNERSHIP.md`, `docs/DEVELOPMENT_SETUP.md`, `docs/ROADMAP.md`, and `docs/SUPABASE_STRATEGY.md` retain historical `future supabase/`, absent-Supabase, or `backend/*` wording.
- Current `AGENTS.md`, root `README.md`, and `docs/ARCHITECTURE.md` supersede that repository-platform wording: Supabase is active and future protected services belong at `services/api`.
- `.ai/tasks/tnyx-158-meal-diary-add-food-quick-add-shell.md` still says `In review`, while current Linear truth is `Done`.
- `.ai/tasks/tnyx-67-meal-categories-readiness.md` records TNYX-67 as `In Progress`, while Linear currently shows unintended post-PR automation status `Done`.

These are governance/documentation drift, not a Nutrition IA/domain ownership blocker. They should not be expanded into this focused readiness task.

## 4. Settings-First Sequencing

Current Linear contracts support:

```text
TNYX-68 minimal Meal Diary Settings shell/navigation
→ TNYX-67 Meal Categories management UI using the existing repository
→ later Quick Add / Meal Editor Meal type activation as consumers
→ later TNYX-113/114/115 durable MealLog lifecycle
```

No current issue requires the Quick Add Meal type popup to precede Settings. TNYX-115 instead depends on TNYX-113 and TNYX-114 and consumes the final active Meal Category state without owning another category source.

## 5. Minimum Next TNYX-68 Slice

Proposal only; no source change:

- Primary entry: `Meal Diary → More / ⋮ → Meal Diary Settings`.
- Minimal page content: one truthful `Meal Categories >` navigation row.
- Route contract owner: `apps/core/lib/src/routing/routes/app_routes.dart`.
- Page owner: `apps/features/nutrition`.
- Route registration, repository/controller injection, and top-bar action composition owner: `apps/app/lib/app/router.dart` and existing app providers.
- Preserve the existing Today action and streak; the visible More/top-bar composition requires owner approval in the separate TNYX-68 task.
- Defer the optional broader `Nutrition Settings → Meal Diary Settings` shortcut until it is separately justified; do not duplicate settings state.
- Exclude Show meal times, Meal Notes, note preview, Meal Reminders, notification delivery, and their persistence from this minimal shell.

## 6. Child-Screen Decisions

- Separate `Archived` section remains the recommended future TNYX-67 Slice C presentation, but its exact visible layout is a Meal Categories child-screen UI decision. It does not block TNYX-54 or the minimal TNYX-68 shell.
- `Restore Defaults` remains excluded from initial Slice C. Its retained-ID-safe semantics are a future TNYX-67 product decision and do not block TNYX-54 or the minimal TNYX-68 shell.

## 7. Hosted Supabase Prerequisite

Read-only verification on project `oykupyiitspujzpwwvuj`:

- status `ACTIVE_HEALTHY`;
- 40 migrations; latest `20260907065602_add_meal_categories_config`;
- nullable/no-default `meal_categories_config jsonb`, CHECK, private validator, retained-ID function and enabled trigger present exactly once;
- RLS enabled; authenticated owner SELECT/INSERT/UPDATE policies present; standalone DELETE policy absent;
- two `user_nutrition_profiles` rows preserved.

TNYX-54 readiness requires zero Supabase migration or mutation.

## 8. Final Classification

`READY — TNYX-54 is sufficiently locked as a Nutrition architecture/domain contract to proceed to a focused TNYX-68 Meal Diary Settings shell readiness slice. No new TNYX-54 implementation or architecture refactor is required. A TNYX-54 Linear status transition requires explicit owner authorization.`

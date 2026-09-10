# TNYX-66 — N0 Nutrition pre-implementation audit & readiness gate

**Status:** Ready
**Primary owner:** `apps/shared` Nutrition contracts
**Affected platforms:** Shared pure-Dart contract only; no platform code changed in this audit

## Owner Approval and Scope Boundary

**Trigger:** None — read-only audit and focused task record.
**Approval status:** The N1.1b scope boundary is owner-approved; separate implementation authorisation was granted after this gate.
**Approval evidence:** Owner decision of 2026-09-10 corrected the slice name to `N1.1b — Implement canonical NutritionSnapshot shared value object`, assigned it to `apps/shared`, and then explicitly authorised implementation/validation/PR publication without merge.
**Approved product/UI/data-shape boundaries:** N1.1b may implement only canonical `NutritionSnapshot`, required current `NutrientId` integration, and pure-Dart contract tests in `apps/shared`.
**Explicit non-changes:** No `MealLogEntry`, `MealLogItemSnapshot`, production source/test implementation, Supabase schema/migration/mutation, repository/provider, UI/route, Quick Add persistence, AI/provider integration, Linear/GitHub mutation, commit, push, PR, or merge.

## Active Handoff

**Planning owner:** Current TNYX-66 audit
**Implementation owner:** None — no implementation authorised
**Review owner:** Owner
**Implementation ownership state:** Not started
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-10
**Branch:** `main`
**HEAD SHA:** `9f19cbb1bedd6495a1d3d7d96ef5f6dd8d16efc9` (`main == origin/main`)
**Observed working-tree state:** Clean apart from unrelated pre-existing work, preserved untouched
**Observed uncommitted/dirty files:** `pubspec.lock` (modified), `.ai/tasks/tnyx-54-nutrition-ia-readiness.md` (untracked), plus this brief
**PR / tracker:** Linear TNYX-54 is Done; TNYX-140 owns the frozen contract-only semantics; TNYX-187 owns N1.1b implementation and blocks TNYX-113. TNYX-153 remains the separate N1.2 package-organization task.
**Current implementation state:** Readiness refresh complete; N1.1b implementation is active under its focused execution brief.
**Relevant execution surface:** `apps/shared/lib/src/nutrition`, `apps/shared/test/nutrition`
**Validation completed at SHA:** `9f19cbb1` — read-only repository/runtime and current Linear inspection; task-brief whitespace check
**Validation remaining:** N1.1b exact-head GitHub CI after PR publication
**Current blocker:** None for the named N1.1b slice
**Open review finding IDs:** None
**Next exact action:** Complete TNYX-187 under `.ai/tasks/tnyx-187-nutrition-snapshot.md`; do not start TNYX-113 or merge the PR.

## 1. Audit Question

Is the repository ready for `N1.1b — Implement canonical NutritionSnapshot shared value object` as the prerequisite before TNYX-113?

Result: **READY for N1.1b only.** The owner resolved the snapshot ownership and optional meal-name decisions. Implementation was authorised separately after this gate.

## 2. Mandatory read order — completed

```text
AGENTS.md                                    read
apps/features/AGENTS.md                      read
apps/core/lib/src/theme/README.md            read (no UI slice in scope)
docs/MODULE_OWNERSHIP.md                     read
docs/README.md docs/ARCHITECTURE.md           read
docs/DEVELOPMENT_SETUP.md docs/ROADMAP.md     read
docs/SUPABASE_STRATEGY.md                    read
docs/screens/nutrition.md, meal-diary.md, meal-plan.md,
  nutrition-targets.md                       read
.ai/README.md .ai/CURRENT.md .ai/DECISIONS.md    read
.ai/workflow.md .ai/FEATURE_DEVELOPMENT.md       read
.ai/tasks/README.md .ai/tasks/TEMPLATE.md        read
.ai/tasks/tnyx-54-nutrition-ia-readiness.md      read (untracked, not modified)
.ai/tasks/canonical-nutrientid-registry-foundation.md  present
runtime: apps/features/nutrition/**, apps/shared/lib/src/nutrition/**, supabase/migrations/**  read
Linear TNYX-54 / 57 / 58 / 59 / 62 / 66 / 67 / 113–117 /
  140 / 158 / 185 / 186                      read
GitHub open PRs and remote branches           read
hosted Supabase migrations/schema/RLS/functions  read-only
```

## 3. Repository readiness

| Area | Result | Evidence at `9f19cbb1` |
|---|---|---|
| Branch / base | PASS | `main == origin/main == 9f19cbb1`, fast-forwarded post-#239 merge |
| Dirty work preserved | PASS | `pubspec.lock` and the untracked TNYX-54 brief untouched; neither committed, stashed nor reset |
| Active PR overlap | PASS | One open PR, **#237**, changes 10 files, all under `apps/core` (`tio_button`, remove-image sheet, their tokens/tests, theme README). It touches **no** `apps/features/nutrition`, no `supabase/`, and no meal/MealLog path. **No overlap with the Nutrition persistence surface.** |
| Remote branch overlap | PASS | Only `tnyx/issue-173-…` (#237) and `tnyx/issue-238-…` (merged, retained by request) exist |
| Nutrition package shape | PASS | `domain/{models,repositories,usecases}`, `data/repositories`, `presentation`, `meal_diary`, `meal_logging` |
| Owner boundaries | PASS | `MODULE_OWNERSHIP.md` assigns Nutrition screens/flows to `apps/features/nutrition`; `apps/app` composes only |
| Shared component reuse | PASS | Calendar/date-time popup owned by `apps/core`; no new abstraction needed for a persistence slice |
| Test/CI baseline | NOT RERUN | Existing focused shared/Nutrition tests were inventoried; this audit changed documentation only |
| Migration overlap | PASS | N1.1b is pure Dart and requires no migration; future MealLog persistence remains a later authorised TNYX-113 concern |

## 4. Persistence surface — verified greenfield

```text
grep MealLogEntry | MealLogItemSnapshot | NutritionSnapshot   across apps/**/*.dart  → 0 matches
supabase/migrations                                            42 files
  meal-related migrations                                      3, all Meal *Categories*
  meal log / food / nutrient table                             none
```

Corroborated by current runtime and hosted metadata rather than assumed:

- `docs/screens/meal-diary.md:6` — "Saving a meal, totals and persistence are not implemented; no diary data source exists yet."
- `docs/screens/meal-diary.md:33` — "Nothing in this flow persists anything … The date/time interaction does not unblock or implement TNYX-113/TNYX-114/TNYX-115."
- Hosted Nutrition tables are `user_nutrition_profiles` and `user_nutrition_targets`; there is no MealLog/food-log table, function, or canonical meal-history owner.
- All 42 hosted migration versions match the 42 repository migration versions through `20260909131518_enforce_meal_category_display_name_shape`.
- Existing owner-access policies use `authenticated` plus `auth.uid() = user_id`; a later MealLog schema slice must define explicit least-privilege grants as well as RLS.

There is no duplicate target/log/daily-total owner to collide with, and no retrofit risk. This is the cheapest possible moment to freeze the contract, which is exactly TNYX-140's stated rationale.

## 5. Dependency state

| Dependency | Linear status | Contract state | Code state |
|---|---|---|---|
| TNYX-66 (this gate) | Backlog | — | audit complete |
| TNYX-54 — N1 IA & domain contracts | **Done**; TNYX-113 still displays the historical relation | Current resulting architecture is present; the earlier Backlog observation was stale and is not a blocker | n/a |
| TNYX-140 — N1.1 NutrientId registry & **NutritionSnapshot** | **Backlog**, contract-only by owner decision | Canonical snapshot semantics are frozen and are the authoritative dependency for N1.1b | `NutritionSnapshot` was absent at gate time |
| NutrientId registry foundation | Historical task is Validated | The task explicitly excluded `NutritionSnapshot` | `apps/shared/lib/src/nutrition/nutrient_id.dart` currently exposes 12 typed IDs and canonical units; no snapshot type exists |
| TNYX-187 — N1.1b Implement canonical NutritionSnapshot shared value object | Backlog at creation | Depends on frozen TNYX-140 and blocks TNYX-113 | Implementation active in its focused branch |
| TNYX-153 — N1.2 Nutrition package feature-first organization | Backlog | Separate package-governance task; never renamed or repurposed | Not part of N1.1b |
| TNYX-113 — MealLog persistence contract | Backlog | Must consume the published N1.1b value object; must not implement it internally | Not implemented |

TNYX-113 references `NutritionSnapshot` in both detailed and manual modes. The owner has now made the missing shared type an explicit standalone prerequisite instead of allowing TNYX-113 to absorb it.

## 6. Stale-doc findings

Recorded rather than silently followed, per `AGENTS.md` source-of-truth rule.

| Doc | Issue |
|---|---|
| `.ai/CURRENT.md` | Last verified **2026-08-23** and remains onboarding-focused; not current Nutrition readiness evidence. |
| `.ai/DECISIONS.md` | D-012/D-013 still describe Supabase as target/not implemented even though current runtime and `supabase/` are active. |
| `docs/MODULE_OWNERSHIP.md` | Retains future `supabase/` and `backend/*` ownership language, conflicting with current active Supabase and future-only `services/api`. |
| `docs/DEVELOPMENT_SETUP.md` | Says no Supabase workspace/config is present and still uses future `backend/*`; current repository contradicts both. |
| `docs/ROADMAP.md` | Retains future `backend/ai-coach`/backend-workspace wording instead of the governed `services/api` boundary. |
| `docs/SUPABASE_STRATEGY.md` | Still describes root Supabase as future and says not to create it, conflicting with current runtime/migrations. |

Neither blocks this gate.

## 7. Owner Decisions and Named Ready Slice

**D1 — Resolved:** TNYX-54 is Done in current Linear. The earlier Backlog observation is stale evidence and is not an active blocker.

**D2 — Resolved:** `NutritionSnapshot` is not implemented inside TNYX-113. TNYX-140 owns the frozen contract-only semantics. A separate prerequisite owns implementation:

```text
N1.1b — Implement canonical NutritionSnapshot shared value object
    depends on TNYX-140 frozen contract
    blocks TNYX-113
```

**D3 — Resolved:** Canonical `MealLogEntry.mealName` is optional. Blank/omitted input persists as `null`/absent; `Quick Add` may be derived only as presentation fallback and is never fabricated persistence truth.

### N1.1b exact scope

- `apps/shared`
- canonical `NutritionSnapshot`
- required current `NutrientId`/registry integration only
- pure-Dart contract tests

The frozen contract requires a versioned typed map (`schemaVersion` plus `Map<NutrientId, num>` in canonical units), absent-key unknown semantics, present zero as known zero, no provenance inside the value object, and rejection of derived-only nutrient values when such registry metadata exists. N1.1b must not invent unsupported NutrientIds, unit conversions, database precision, upper nutrition limits, provider aliases, aggregation APIs, or persistence encoding outside the contract.

### Explicit exclusions

- `MealLogEntry` / `MealLogItemSnapshot`
- Supabase/migration
- repositories/providers
- UI/routes
- Quick Add persistence
- AI/provider integrations

No Supabase migration is needed for N1.1b. Any future MealLog physical schema remains a later TNYX-113 slice after N1.1b is published and consumed as a dependency.

## 8. Validation

Read-only audit.

```text
git status --short --branch  -> main tracks origin/main; protected pubspec.lock and TNYX-54 brief preserved
git diff --check             -> no tracked whitespace errors
git diff --no-index --check  -> no whitespace error in this untracked brief; exit 1 only because the file differs from NUL
runtime/test inventory       -> inspected; no Flutter/Dart suite rerun for this audit-only brief
```

Expected N1.1b validation after separate implementation authorisation:

```text
focused apps/shared NutritionSnapshot tests
apps/shared analysis
missing-vs-zero and immutable/value-semantics coverage
schemaVersion and NutrientId integration coverage
negative/non-finite and derived-only rejection where required by the frozen contract
git diff --check
```

## 9. Gate result

```text
READY — N1.1b — Implement canonical NutritionSnapshot shared value object
```

This readiness applies only to the named pure-Dart prerequisite. Separate owner authorisation later allowed TNYX-187 implementation and PR publication, but not TNYX-113, Supabase work, or PR merge.

# TNYX-66 — N0 Nutrition pre-implementation audit & readiness gate

**Status:** Ready — gate re-run for TNYX-113
**Primary owner:** `apps/shared` Nutrition contracts
**Affected platforms:** Shared pure-Dart contract only; no platform code changed in this audit

## Owner Approval and Scope Boundary

**Trigger:** None — read-only audit and focused task record.
**Approval status:** Audit only. No implementation is authorised by this refresh.
**Approval evidence:** Owner instruction of 2026-09-10 requested a fresh TNYX-66 readiness refresh specifically for TNYX-113, explicitly audit-only, and supplied the mealName and provenance owner decisions recorded below.
**Approved product/UI/data-shape boundaries:** None. Identifying a candidate slice is not authorisation to build it.
**Explicit non-changes:** No MealLog source types, production Dart, tests, branch, Supabase migration/mutation, Quick Add saving, provenance implementation, FatSecret/AI/photo/voice/barcode integration, UI, PR merge, branch deletion, or Linear mutation.

## Active Handoff

**Planning owner:** Current TNYX-66 audit
**Implementation owner:** None for this gate. The selected N20A-1 slice is implemented under TNYX-188.
**Review owner:** Owner
**Implementation ownership state:** Complete for the selected N20A-1 slice; this gate itself remains audit-only
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-10
**Branch:** implementation and review work is on `tnyx/tnyx-188-meal-log-capture-source`. The audit that produced this gate was performed against post-merge `main`.
**HEAD SHA:**

```text
Base / main anchor:
522cf0b657be11c19458075c2f788afa5d60b51d   squash merge of PR #240

Current published implementation head:
See PR #241; GitHub is authoritative for the current post-amend SHA.
```

The exact head is deliberately not embedded here, because every governance amend would change it again and cause self-referential SHA churn.

**Observed working-tree state:** Protected unrelated work preserved untouched throughout the audit and the implementation branch.
**Observed uncommitted/dirty files:** Only unrelated protected work — `pubspec.lock` (modified, SHA-256 `004DE1A0…300B1C`) and `.ai/tasks/tnyx-54-nutrition-ia-readiness.md` (untracked). This brief is **not** dirty work: it is intentionally committed in PR #241 as the readiness artifact that selected N20A-1.
**PR / tracker:** TNYX-187 **Done** (merged 2026-09-10). TNYX-54 **Done**. TNYX-66 remains **Backlog** and is still the active gate. TNYX-113 remains **Backlog**, blocked by 187/54/66, and blocks 114/115/116/117. TNYX-140 remains Backlog as contract-only semantic owner.
**Current implementation state:** `NutritionSnapshot` exists on `main` and is verified. The canonical `MealLogCaptureSource` contract selected by this gate is implemented on PR #241 but is **not yet merged to `main`**. The MealLog aggregate, item snapshot, provenance, repositories and persistence all remain greenfield.
**Relevant execution surface:** `apps/shared/lib/src/nutrition`, `apps/shared/test/nutrition`, `apps/features/nutrition/lib/src/meal_logging`, `supabase/migrations`
**Validation completed at SHA:** `522cf0b6` — read-only repository/GitHub/Linear/hosted-Supabase inspection; `apps/shared` nutrition tests rerun 20/20. Findings below describe `main` at that SHA, before the PR #241 branch existed.
**Validation remaining:** None for this gate. PR #241 carries its own validation under TNYX-188.
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Finish PR #241 review and obtain the owner merge decision. N20A-1 authorisation was already granted and must not be requested again, and the capture-source contract must not be reimplemented. The next TNYX-113 sub-slice, including the deferred provenance/item work, requires a fresh TNYX-66 readiness refresh **after** PR #241 merges. This gate is not readiness for it.

## 1. Audit Question

Is the repository ready for the smallest safe first implementation slice of TNYX-113 — Canonical MealLogEntry & MealLogItemSnapshot persistence contract?

Result: **READY for one named sub-slice only** — the canonical capture-source value contract. The full aggregate is not yet safely constructible, because TNYX-114's time semantics are unresolved, and provider/item provenance is deferred to its own later sub-slice.

## 2. Mandatory read order — completed

```text
AGENTS.md  apps/features/AGENTS.md                       read
README.md  docs/ARCHITECTURE.md  docs/MODULE_OWNERSHIP.md read
docs/DEVELOPMENT_SETUP.md  docs/ROADMAP.md               read
docs/SUPABASE_STRATEGY.md  docs/POST_MERGE_SYNC.md       read
.ai/README.md .ai/CURRENT.md .ai/DECISIONS.md            read
.ai/workflow.md .ai/FEATURE_DEVELOPMENT.md               read
.ai/tasks/README.md .ai/tasks/TEMPLATE.md                read
.ai/tasks/tnyx-187-nutrition-snapshot.md                 read
.ai/tasks/tnyx-54-nutrition-ia-readiness.md              read (untracked, not modified)
runtime: apps/shared/lib/src/nutrition/**, apps/shared/lib/src/workout/**,
         apps/features/nutrition/**, supabase/migrations/**   read
Linear TNYX-54/66/112/113/114/115/116/117/140/143/153/187     read-only
GitHub PR #240 merge state, open PRs, remote branches         read-only
hosted Supabase migrations + public tables                    read-only
```

## 3. Repository readiness

| Area | Result | Evidence at `522cf0b6` |
|---|---|---|
| Remote anchor | PASS | `origin/main == 522cf0b6`, matches the expected squash merge of PR #240 exactly |
| Local sync | PASS | `git fetch origin main:main` fast-forwarded `9f19cbb1 → 522cf0b6` without checkout, so the dirty working tree was never touched. No merge commit. |
| Dirty work preserved | PASS | `pubspec.lock` SHA-256 unchanged; TNYX-54 brief still untracked; nothing staged, stashed, reset or deleted |
| Active PR overlap | PASS | Only open PR is **#237**, `apps/core` remove-image confirmation UI. No Nutrition, MealLog or Supabase overlap. |
| Remote branch overlap | PASS | Three remote branches, none targeting MealLog. No other agent on this surface. |
| Merged branch retained | PASS | `tnyx/tnyx-187-nutrition-snapshot` deliberately not deleted; no cleanup authorised |
| MealLog runtime | GREENFIELD at `522cf0b6` | `MealLogEntry`/`MealLogItemSnapshot`/`MealLogProvenance`/`captureSource` → 0 matches across `apps/` and `supabase/`. Superseded in part: `MealLogCaptureSource` now exists on PR #241, still unmerged. The aggregate, item snapshot, provenance and persistence stay greenfield. |
| Test baseline | PASS | `apps/shared` nutrition suite rerun on merged content: 20/20 |

## 4. Merged prerequisite verified — `NutritionSnapshot`

Source: `apps/shared/lib/src/nutrition/nutrition_snapshot.dart`, exported through `src/nutrition/nutrition.dart` → `shared.dart`.

| Required semantic | Verified | Evidence |
|---|---|---|
| missing nutrient != zero | PASS | `amountFor` returns `null` when absent; `containsNutrient` separates absent from zero; `toJson` encodes only present keys |
| negative rejected | PASS | `_validateAndCopy` throws `ArgumentError` on `amount < 0` |
| non-finite rejected | PASS | same guard rejects `!amount.isFinite` (NaN and both infinities) |
| zero allowed | PASS | only `< 0` is rejected |
| canonical NutrientId keys | PASS | `Map<NutrientId, num>`; storage decode via `NutrientId.fromStorageValue` |
| immutable / value semantics | PASS | `final class`, defensive copy plus `Map.unmodifiable`, order-independent `==`/`hashCode` |
| provider-independent | PASS | only `schemaVersion` and `nutrients`; no provider, capture or ID fields |

TNYX-113 can consume this directly. **No competing snapshot type should be defined.** Unknown future nutrient keys are ignored rather than remapped, so a typed snapshot retains only currently registered identities — acceptable for MealLog, worth noting for any future raw-passthrough need.

One observation carried forward, not a blocker: `NutrientId.derivedOnly` is `false` for all twelve entries, so the derived-only rejection branch is currently unreachable and untested.

## 5. Persistence surface — greenfield confirmed

Still accurate. PR #241 adds a pure-Dart value contract only and creates no table, migration or repository, so the persistence surface remains greenfield.

```text
repository migrations   42   latest 20260909131518_enforce_meal_category_display_name_shape
hosted migrations       42   identical ledger, no drift
hosted public tables    12   all RLS enabled
meal log / food log / diary-entry table or function   none
```

The three meal-related migrations are all Meal **Categories** configuration, not meal history.

Conventions a future MealLog table must follow, taken from `public.body_weight_logs`, the closest existing per-user log:

```text
id           uuid primary key default gen_random_uuid()
user_id      uuid not null references public.users(id) on delete cascade
timestamps   timestamptz not null default timezone('utc', now())
             created_at + updated_at + trg_*_updated_at → public.set_row_updated_at()
jsonb        not null default '{}'::jsonb + jsonb_typeof(...) = 'object' check
enums        no Postgres enum types exist anywhere; convention is text + CHECK
index        (user_id, <time> desc)
RLS          enabled + four explicit own-row policies using (select auth.uid()) = user_id
grants       explicit select/insert/update/delete to authenticated and service_role
```

`public.users` is the domain FK root, not `auth.users`. The nutrient-goals precedent stores nutrient-keyed data as a versioned JSONB envelope where an absent key means "not configured" — the same missing-vs-zero semantic `NutritionSnapshot.toJson()` already produces.

**Physical persistence must be its own later slice (Slice B or later), not Slice A.**

## 6. Ownership decision — `apps/shared`

Evidence, not assumption:

- `apps/shared/lib/src/workout/domain/models/training_session.dart` already places a durable actual-session entity with `id` and timestamps in `apps/shared`, alongside a repository contract. Actual-history entities are an established `apps/shared` responsibility.
- `AGENTS.md` assigns shared Dart entities/value objects and core domain logic to `apps/shared`.
- `apps/features/nutrition/lib/src/domain/models/` holds config/policy/presentation-facing types (meal categories, targets, profile), not durable history.
- `apps/features/nutrition/lib/src/meal_logging/` contains presentation only — no domain or data layer.
- `apps/core` is excluded by rule: it owns design-system and routing contracts, never Nutrition history truth.

MealLog domain types belong in `apps/shared`. Keep new files flat beside the existing `nutrition/` files; do not create speculative folders, and do not pre-empt TNYX-153's N1.2 package reorganisation.

## 7. Owner decisions recorded

**D3 — mealName is optional.** User-supplied name persists as canonical `mealName`; blank persists as `null`/absent; `Quick Add` may be derived as a display fallback only and is never fabricated durable truth.

Runtime already complies: `quick_add_editor_sheet.dart` uses hint `Meal name (optional)` and returns `null` for empty trimmed input. `Quick Add` appears only as the sheet title. **No runtime conflict.**

**D4 — capture source and provider are separate concepts.** Capture source covers `quickAdd`, `foodSearch`, `barcode`, `text`, `voice`, `photo`, `recent`, `savedMeal`, `plannedMeal`. Provider identity (`providerKey`, `sourceFoodId`, `sourceServingId`) is optional provenance. Neither belongs inside `NutritionSnapshot`.

**D5 — provider provenance is never historical truth.** Durable snapshots remain readable and unchanged if provider/catalog data is deleted or changed. History is never recomputed by re-fetching a provider.

## 8. Tracker deltas — reported, not applied

| Item | Current Linear wording | Owner decision |
|---|---|---|
| Capture source list | TNYX-113 lists `text \| voice \| photo \| foodSearch \| recent \| savedMeal \| plannedMeal \| quickAdd` | `barcode` is missing and must be added |
| `mealName` | TNYX-113 aggregate shows `mealName` without `?`, implying required | It is optional (`mealName?`), per D3 |

Both are wording-only. The owner decisions above remove the ambiguity, so neither is a blocker. Do not mutate Linear from this audit.

## 9. Stale-doc findings

| Doc | Issue |
|---|---|
| `.ai/CURRENT.md` | Last verified 2026-08-23, still an Onboarding O7 snapshot; not current Nutrition evidence |
| `.ai/DECISIONS.md` | D-012/D-013 still call Supabase "target, not implemented" while it is active infrastructure |
| `docs/MODULE_OWNERSHIP.md`, `docs/DEVELOPMENT_SETUP.md`, `docs/ROADMAP.md`, `docs/SUPABASE_STRATEGY.md` | Retain future-`supabase/` or `backend/*` wording superseded by `AGENTS.md` and ADR-0007 |
| `.ai/tasks/tnyx-54-nutrition-ia-readiness.md` | Records 40 migrations, latest `20260907065602`; actual is 42, latest `20260909131518` |

None blocks this gate.

## 10. Boundary findings for adjacent issues

| Issue | Status | Boundary held by Slice A |
|---|---|---|
| TNYX-114 time/timezone | Backlog, **unresolved** | Its DST/ambiguous-time and local-date resolver policy is not frozen, and the issue itself records that it stays blocked by TNYX-113. Slice A carries **no** time field, so it cannot swallow TNYX-114. |
| TNYX-115 Quick Add create/edit | Backlog | No repository, provider, UI or `Log Meal` enablement in Slice A |
| TNYX-116 idempotency/offline/concurrency | Backlog | No `version`, retry or conflict semantics in Slice A |
| TNYX-117 integrated acceptance | Backlog | Unaffected |
| Membership / ads / quotas | n/a | No tier, entitlement, ad-state or lifetime-cap field enters MealLog truth. Ad outcome must never gate a durable save; future quotas belong in an entitlement layer before repository create. |

## 11. Proposed smallest TNYX-113 Slice A

```text
N20A-1 — Canonical MealLog capture-source value contract
```

Rationale: it is the only part of the TNYX-113 aggregate with no dependency on unresolved time semantics, no dependency on unresolved serving/normalisation typing, and no persistence dependency. It is a standalone value contract, so it is coherent and independently testable without producing a partial or invalid aggregate.

Exact boundary in `apps/shared`:

```text
lib/src/nutrition/meal_log_capture_source.dart   MealLogCaptureSource enum, 9 values incl. barcode,
                                                 stable storageValue + forward-unknown decode,
                                                 mirroring the existing NutrientId pattern
lib/src/nutrition/nutrition.dart                 add one export
test/nutrition/meal_log_capture_source_test.dart
```

The nine canonical identities are `quickAdd`, `foodSearch`, `barcode`, `text`, `voice`, `photo`, `recent`, `savedMeal` and `plannedMeal`.

Slice A is capture-source only. It defines **no** `MealLogProvenance` wrapper and **no** provider, template or plan reference field. A one-field wrapper around a single enum would be speculative abstraction, and the real provenance shape must come from fresh evidence in its own slice.

Deferred to later slices with explicit reasons:

- **provider/item provenance** — `MealLogProvenance`, `providerKey`, `sourceFoodId`, `sourceServingId`, `sourceMealLogEntryId`, `sourceSavedMealId`, `sourcePlannedMealId`. These belong to a separate TNYX-113 sub-slice that must first confirm item-level ownership from fresh audit. Provenance is item-level because one detailed meal may mix items from different origins:

```text
MealLogEntry
  captureSource = photo

MealLogItemSnapshot A
  providerKey = fatsecret
  sourceFoodId = ...
  sourceServingId = ...

MealLogItemSnapshot B
  providerKey = null
```

  `providerKey` is never a `MealLogCaptureSource`. A provider may resolve the food behind several capture modes without changing the mode: `photo + FatSecret → captureSource = photo`, `food search + FatSecret → captureSource = foodSearch`, `barcode + FatSecret → captureSource = barcode`.

  The downstream requirement is preserved: when provider origin is known, durable item provenance must eventually retain it even if the UI never displays it, and historical nutrition still comes from the durable `NutritionSnapshot` rather than a provider re-fetch.

- `MealLogEntry` and `MealLogMode` — need TNYX-114 time semantics and mode-exclusivity invariants.
- `MealLogItemSnapshot` — needs serving quantity/unit and normalised amount/unit typing plus `sourceSnapshot`/`manualOverrides` shape.
- All Supabase persistence, repository wiring, and delete semantics.

## 12. Validation plan for Slice A

Proportional, and **not yet run** — this task is readiness-only.

```text
dart format <owned files>
dart analyze apps/shared
dart test test/nutrition/meal_log_capture_source_test.dart
dart test                       full apps/shared suite
melos analyze / melos test      CI-equivalent workspace check
git diff --check
```

Expected coverage, limited to what Slice A owns:

- all nine capture sources round-trip through stable storage values, `barcode` included;
- an unknown future storage value decodes to unknown, is never remapped and never falls back to `quickAdd`;
- Quick Add stays distinct from Food Search;
- provider names such as `fatsecret` are rejected as capture sources, keeping capture mode separate from provider identity;
- Photo, Voice and Text remain capture modes rather than provider identities;
- deterministic enum identity and hash semantics;
- no provider, nutrition, membership, entitlement or ad field exists on the type.

Provider provenance has no test in Slice A because it is not implemented there.

## 13. Gate result

```text
READY — N20A-1 — Canonical MealLog capture-source value contract
```

Readiness applies only to that named sub-slice. It is not implementation authorisation, and it does not extend to `MealLogEntry`, `MealLogItemSnapshot`, Supabase persistence, Quick Add saving, or TNYX-114/115/116/117.

# TNYX-66 — N0 Nutrition pre-implementation audit & readiness gate

**Status:** Ready — N20A-3 manual-mode `MealLogEntry` core aggregate contract
**Primary owner:** Nutrition architecture / `apps/shared` domain contracts
**Affected platforms:** Shared Dart domain only for the approved next slice; no UI or persistence change is authorised by this gate

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product/domain slice.
**Approval status:** Approved for one bounded slice only: N20A-3 manual-mode `MealLogEntry` core aggregate contract.
**Approval evidence:** Owner instruction on 2026-09-10 requested the current governance branch be merged and work continue from the TNYX-66 audit so development can move forward. The resulting fresh audit narrows the previously proposed full aggregate to the smallest decision-free manual-mode contract.
**Approved product/UI/data-shape boundaries:** Pure `apps/shared` domain work only. The canonical `MealLogEntry` type may gain manual-mode construction and the value representation needed to preserve TNYX-114 consumed-instant/local-date/timezone semantics. No production UI is in scope.
**Explicit non-changes:** No `MealLogItemSnapshot`, detailed-mode construction, serving/normalization model, provider selection/integration, Supabase table/column/RLS/grant/migration, repository wiring, Quick Add save wiring, ads/entitlement behavior, concurrency/version policy, UI, or feature navigation.

`READY` below applies only to that named slice. It does not mark all of TNYX-113 ready.

## Active Handoff

**Planning owner:** TNYX-66 readiness gate
**Implementation owner:** None until the N20A-3 implementation branch starts
**Review owner:** Owner
**Implementation ownership state:** Approved and ready to start after this readiness record is merged
**Ownership transition:** Previous Nutrition value-contract slices are merged; next implementation owner should reconstruct from the current `main` anchor below
**Repository state last verified:** 2026-09-10
**Branch:** `tnyx/tnyx-66-manual-meal-log-entry-readiness` for this docs-only gate refresh
**Base / main anchor:** `9cc62862eafbb158e06062bdf1c9cbf4c8789199`, squash merge of PR #245
**Observed working-tree state:** GitHub/API-based audit; no local working tree was available, so no local dirty-state claim is made.
**Observed uncommitted/dirty files:** Not observable through the repository API. The next implementation owner must run the normal local reconstruction before source edits when a local worktree is used.
**PR / tracker:** PR #245 is **MERGED**. No open GitHub PR was found after the merge. TNYX-187, TNYX-188, TNYX-189 and TNYX-114 are **Done**. TNYX-66 and TNYX-113 remain **Backlog** and TNYX-66 remains the mandatory Nutrition gate.
**Current implementation state:** `NutrientId`, `NutritionSnapshot`, `MealLogCaptureSource` and `MealLogMode` are merged on `main` and exported from `apps/shared`. No runtime `MealLogEntry`, `MealLogItemSnapshot`, MealLog repository, or MealLog persistence exists.
**Relevant execution surface:** `apps/shared/lib/src/nutrition`, `apps/shared/test/nutrition`
**Validation completed at SHA:** `9cc62862` — read-only GitHub/Linear/Supabase reconciliation plus current shared Nutrition source/test inventory.
**Validation remaining:** On the implementation slice, run the smallest applicable Dart/Flutter package analysis/tests and exact diff/scope audit before handoff.
**Current blocker:** None for N20A-3 manual-mode core aggregate. Detailed mode remains blocked on the item/serving contract described below.
**Open review finding IDs:** None
**Next exact action:** Merge this readiness-only record, then start one N20A-3 implementation branch from the then-current `main`; create/update its focused `.ai/tasks/*` execution brief before source changes.

## 1. Current Readiness Question

What is the next smallest coherent and independently testable TNYX-113 implementation slice after the merged `NutritionSnapshot`, `MealLogCaptureSource`, `MealLogMode` contracts and completion of TNYX-114 time semantics?

Result: **READY for N20A-3 — manual-mode `MealLogEntry` core aggregate contract only.**

The earlier gate was stale because it classified TNYX-114 as Backlog/unresolved. Linear now records TNYX-114 as Done. That removes the time-semantics blocker for the manual path. The full detailed aggregate is still not ready because `MealLogItemSnapshot` serving/normalization/provenance shape remains unresolved.

## 2. Current Repository / Dependency Evidence

Verified on `main` at `9cc62862`, exported through `apps/shared/lib/src/nutrition/nutrition.dart`:

```text
NutrientId            12 identities, stable storage values
NutritionSnapshot     missing != zero, negative/non-finite rejected, immutable
MealLogCaptureSource  stable capture-source identities incl. barcode
MealLogMode           manual | detailed, unknown -> null, no fallback
```

Current `apps/shared/lib/src/nutrition` contains only:

```text
meal_log_capture_source.dart
meal_log_mode.dart
nutrient_id.dart
nutrition.dart
nutrition_snapshot.dart
```

Current `apps/shared/test/nutrition` contains the corresponding focused tests. No `MealLogEntry` or `MealLogItemSnapshot` source/test exists yet. Repository search found no existing shared date-only MealLog value object; any representation introduced by N20A-3 must remain domain-bounded rather than creating a speculative cross-domain abstraction.

Existing shared entity convention supports plain string identity: `TrainingSession` uses `String id`, so N20A-3 does not need to invent a MealLog ID value-object hierarchy.

### TNYX-114 is now resolved as a semantic dependency

Current Linear status: **Done** on 2026-09-10.

The locked contract distinguishes:

```text
consumedAt
= canonical instant for chronology

consumedLocalDate
= user-intended local calendar date used for Diary identity/grouping

consumedTimezoneId / consumedUtcOffsetMinutes
= logging/edit context for deterministic reconstruction/presentation
```

Historical grouping must not move merely because the device timezone changes. Explicit date/time editing may intentionally move the entry while keeping the same `MealLogEntry.id`. Timezone ID is preferred when available, and DST ambiguous/nonexistent local times must be handled deterministically by the responsible resolver/feature boundary rather than fabricated by the aggregate.

N20A-3 therefore stores the already-resolved semantic facts. It does **not** need to implement the date/time wheel, timezone database/resolver, Quick Add interaction, or persistence conversion in the same slice.

### Supabase remains greenfield for MealLog

Hosted verification on project `oykupyiitspujzpwwvuj` on 2026-09-10:

```text
project status: ACTIVE_HEALTHY
Postgres: 17
hosted migrations: 42
latest: 20260909131518_enforce_meal_category_display_name_shape
public tables: 12
public tables with RLS enabled: 12/12
MealLog / food-log / diary-entry tables: 0
```

This gate performs no hosted mutation. Physical MealLog persistence requires its own later fresh audit and owner-approved table/column slice.

### Existing Supabase conventions to preserve for the later persistence audit

Context only. These are observations, not a MealLog schema and not migration authorisation.

| Observed convention | Evidence | Strength |
|---|---|---|
| Keys are `uuid`, with shape following cardinality | Generated-`id` occurs on multi-row entities such as `user_devices`, `body_weight_logs`, `user_body_goals`; one-row-per-user resources commonly use `user_id` as key. No serial/integer key declaration was found in the 42-migration audit. | Useful analogue only. Exact MealLog key shape is a later persistence decision. |
| Ownership FK has two historical generations | Both `auth.users(id)` and `public.users(id)` exist historically; newer canonical owner tables use `public.users` as domain root. | Do not assume repository-wide uniformity. Re-audit exact MealLog owner FK later. |
| Timestamps use timezone-aware values | Existing declarations use `timestamptz` with UTC defaults; no non-timezone-aware timestamp declaration was found in the prior 42-migration audit. | Strong preference, but exact MealLog columns/nullability remain unfrozen. |
| Shared `updated_at` trigger is a newer pattern | Seven newer surviving tables use `public.set_row_updated_at()`, while older tables with `updated_at` do not all use it. | Reuse if chosen; do not pre-authorise it here. |
| Validated `jsonb` shapes exist | Inline object checks and a function-backed `meal_categories_config` validator both exist. | Does not preselect JSONB for MealLog. |
| PostgreSQL enum types are not used today | Constrained values are represented with text + checks in current migrations. | Observation, not a mandate. |
| Comparable log tables index user + descending time | `body_weight_logs` and `user_body_goals` provide comparable multi-row per-user evidence. | Re-audit query shape before adding a MealLog index. |
| Own-row RLS is established on current public tables | Hosted state reports RLS enabled on all 12 public tables; several newer tables use explicit select/insert/update/delete owner policies. | Future MealLog must define and verify its own policy set. |
| Explicit grants exist but are not universal | Newer canonical tables commonly grant to `authenticated` and `service_role`, but historical coverage is mixed. | Future MealLog grants must be explicit in its security audit. |

## 3. Locked Owner / Domain Decisions

### Meal name

```text
user enters meal name -> persist canonical mealName
blank meal name       -> mealName = null / absent
blank saved-record display fallback -> "Quick Log"
```

`Quick Log` is presentation fallback only and must never be persisted as fabricated `mealName`.

### Manual mode is first-class actual history

TNYX-113 explicitly defines:

```text
mode = manual
manualNutritionSnapshot = user-entered canonical nutrition
items = absent/empty by contract
```

Manual mode must not fabricate food/catalog identities merely to make the aggregate look like detailed mode.

### Capture source, provider provenance, and nutrition are distinct

```text
NutritionSnapshot     = canonical normalized nutrition truth
MealLogCaptureSource  = how logging was initiated/captured
provider provenance   = where a specific detailed structured item came from
```

N20A-3 may compose the existing capture-source value into the manual aggregate without inventing provider identity. Provider-specific fields remain out of scope.

### Identity/edit boundary

```text
new actual log -> new id
edit actual log -> same id
repeat/re-log -> new id
```

N20A-3 may encode identity as data, but repository mutation/edit transactions remain a later slice.

## 4. Carried-Forward Audit Findings

These findings remain reported, not silently bundled into N20A-3.

### Tracker deltas — TNYX-113

| Item | Current wording | Current correction |
|---|---|---|
| Capture-source list | Provenance examples omit `barcode` | Runtime `MealLogCaptureSource.barcode` exists; tracker example is stale. |
| `mealName` | Aggregate sketch shows non-null-looking `mealName` | Locked decision is optional/null when blank. |
| Item `sourceType` | Appears beside `providerKey` | May overlap conceptually with meal-level capture source; must be resolved in the item/provenance slice. |

### Stale Quick Add fallback references

Two older merged task briefs still use `Quick Add` as the blank saved-record display fallback. The locked fallback is `Quick Log`. This is a separate docs cleanup and does not block N20A-3.

### Other stale documentation

`.ai/CURRENT.md`, parts of `.ai/DECISIONS.md`, `docs/DEVELOPMENT_SETUP.md`, and older future-`backend/` wording remain stale against current runtime/ADR/governance evidence. They should be corrected in focused documentation work, not bundled into this domain slice.

A separate governance discrepancy was also observed after PR #245: root `AGENTS.md` references `.github/POST_MERGE_SYNC.md`, but that file is not present on current `main`. This does not affect the Nutrition readiness classification and must not be repaired inside N20A-3.

## 5. Candidate Audit For The Next Sub-Slice

### Candidate A — N20A-3 manual-mode `MealLogEntry` core aggregate — READY

This is the smallest slice that now removes a real implementation gap without consuming unresolved detailed-item decisions.

Minimum semantic surface:

```text
MealLogEntry (manual construction only for this slice)
  id
  userId
  mode = MealLogMode.manual
  mealCategoryId
  mealName?                   // blank normalizes to absent/null
  consumedAt                  // already-resolved canonical instant
  consumedLocalDate           // user-intended date identity, timezone-stable
  consumedTimezoneId?
  consumedUtcOffsetMinutes?
  captureSource?              // existing MealLogCaptureSource, if present
  manualNutritionSnapshot     // required NutritionSnapshot
  createdAt
  updatedAt
```

Implementation guardrails:

- expose no detailed-mode constructor/factory until `MealLogItemSnapshot` is frozen;
- do not add fake/empty item records to manual mode;
- do not add provider IDs or provider payloads;
- do not implement local-time-to-instant/DST resolution inside the aggregate;
- do not derive `consumedLocalDate` from the device's current timezone;
- do not add persistence DTO/table naming merely because fields now exist in Dart;
- do not add `version` yet; TNYX-116 owns idempotency/concurrency policy;
- keep any new date-only representation Nutrition-domain bounded unless actual cross-domain reuse is proven;
- add focused tests for manual-mode invariants, date identity, blank optional meal name, immutable nutrition composition, and equality/codec behavior only where the chosen existing package convention requires it.

This slice intentionally establishes a canonical `MealLogEntry` type while exposing only the manual path. Later detailed support extends that same aggregate after item contracts are ready; it must not create a parallel competing aggregate.

### Candidate B — full/detailed `MealLogEntry` aggregate — BLOCKED

Still depends on `MealLogItemSnapshot`. Building detailed construction now would force unresolved serving, normalization, source snapshot, manual override, and provider provenance decisions into the aggregate.

### Candidate C — `MealLogItemSnapshot` — BLOCKED

Requires exact typing/semantics for:

```text
quantity
servingUnit
normalizedAmount?
normalizedUnit?
sourceSnapshot?
manualOverrides?
```

Those are not yet frozen. A placeholder item type would create migration/API debt rather than a coherent domain contract.

### Candidate D — provider/item provenance — BLOCKED

TNYX-123 still owns provider capability/readiness, licensing/regional concerns, normalized food identity, provenance and confidence boundaries. Do not freeze provider-specific identifiers from N20A-3.

## 6. Why READY Is Safe Now

The previous shortest unblock was TNYX-114. That dependency is complete in Linear, and the manual path is explicitly independent from detailed item snapshots by TNYX-113 contract.

```text
NutritionSnapshot      Done / merged
MealLogCaptureSource   Done / merged
MealLogMode            Done / merged
TNYX-114 time semantics Done
        ↓
manual MealLogEntry core aggregate
        ↓ later
physical persistence audit
repository/create-edit integration
TNYX-115 Quick Add create/edit
```

Serving normalization and provider identity are still necessary for **detailed** logging, but they are not prerequisites for representing a first-class manual actual log.

## 7. Adjacent Boundaries

- **TNYX-114:** semantic dependency is Done; persistence/timezone integration remains downstream through TNYX-113/repository work.
- **TNYX-115:** Quick Add create/edit integration remains separate; no `Log Meal` save wiring in N20A-3.
- **TNYX-116:** idempotency, offline retry and concurrency remain separate; do not add a `version` contract speculatively.
- **TNYX-117:** integrated acceptance remains downstream.
- **TNYX-123:** provider/barcode/provider-provenance work remains separate from the manual aggregate.
- **Supabase:** physical persistence remains greenfield and requires its own fresh readiness + owner-approved table/column scope.
- **Membership/ads:** never canonical MealLog history truth; no plan tier, ad-state or lifetime-cap field belongs in this aggregate.
- **UI:** N20A-3 is non-visual; existing Quick Add date/time UI decisions are not implementation scope here.

## 8. Gate Result

`READY — N20A-3 manual-mode MealLogEntry core aggregate contract only.`

This READY classification authorises one bounded pure-domain implementation slice after this readiness record is merged. It does **not** authorise detailed-mode construction, `MealLogItemSnapshot`, provider integration, persistence/schema/RLS, repository wiring, Quick Add save integration, or UI changes.

After N20A-3 is validated, refresh TNYX-66 again before selecting the next Nutrition implementation slice.
# TNYX-66 — N0 Nutrition pre-implementation audit & readiness gate

**Status:** Ready — post-PR-#241 refresh for TNYX-113
**Primary owner:** Nutrition architecture / `apps/shared` domain contracts
**Affected platforms:** Readiness/governance only; selected slice is pure Dart

## Owner Approval and Scope Boundary

**Trigger:** Readiness refresh before the next Nutrition implementation slice
**Approval status:** N20A-2 readiness completed; implementation was authorised separately by owner `go` on 2026-09-10.
**Approval evidence:** Post-PR-#241 audit selected exactly `N20A-2 — Canonical MealLog mode value contract`; owner then authorised that exact slice, validation and one PR, without merge.
**Approved product/UI/data-shape boundaries:** N20A-2 may add only `MealLogMode`, its shared export, focused tests and execution brief. No full MealLog aggregate or persistence.
**Explicit non-changes:** No `MealLogEntry`, `MealLogItemSnapshot`, provider provenance, serving model, consumed-time/timezone logic, Supabase schema/mutation, repository wiring, Quick Add save, UI/routes, membership, ads, quotas, or branch cleanup.

## Active Handoff

**Planning owner:** TNYX-66 readiness gate
**Implementation owner:** TNYX-189
**Review owner:** PR #242 final review
**Implementation ownership state:** N20A-2 implemented on PR #242; not merged
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-10
**Branch:** `tnyx/tnyx-189-n20a-2-canonical-meallog-mode-value-contract`
**HEAD SHA:** Current PR #242 head is authoritative on GitHub; exact SHA is not embedded here to avoid self-referential amend churn.
**Base / main anchor:** `6089d40676114cf941bc04b7e463986ba59e7467`, squash merge of PR #241
**Observed working-tree state:** Implementation is published remotely; owner-reported unrelated local protected state was not touched by the remote write path.
**Observed uncommitted/dirty files:** Owner-reported protected modified root `pubspec.lock` and untracked `.ai/tasks/tnyx-54-nutrition-ia-readiness.md`. This TNYX-66 brief is intentionally committed as the readiness artifact for N20A-2.
**PR / tracker:** TNYX-188 Done; TNYX-189 In Progress under TNYX-113; PR #242 open and unmerged. TNYX-113 remains Backlog.
**Current implementation state:** `NutritionSnapshot` and `MealLogCaptureSource` are merged on `main`. `MealLogMode` is implemented on PR #242. MealLog aggregate, item snapshot, provenance, repositories and persistence remain unimplemented.
**Relevant execution surface:** `apps/shared/lib/src/nutrition`, `apps/shared/test/nutrition`
**Validation completed at SHA:** Post-#241 readiness audit against `6089d406`; merged capture-source tests and current tracker/provider boundaries were inspected.
**Validation remaining:** PR #242 exact-head CI and final review.
**Current blocker:** None for N20A-2.
**Open review finding IDs:** See PR #242; GitHub review state is authoritative.
**Next exact action:** Complete PR #242 exact-head validation/final review and obtain owner merge decision. Do not reimplement N20A-2. After merge, the next TNYX-113 sub-slice requires a fresh TNYX-66 readiness refresh.

## 1. Current Readiness Question

What is the next smallest coherent and independently testable TNYX-113 implementation slice after the merged `MealLogCaptureSource` contract?

Result: **READY for `N20A-2 — Canonical MealLog mode value contract` only.**

## 2. Current Repository / Dependency Evidence

- `main == 6089d40676114cf941bc04b7e463986ba59e7467` at the audit anchor, PR #241 squash merge.
- TNYX-188 is Done and `MealLogCaptureSource` is merged with nine stable capture identities and null-returning unknown decode.
- `NutritionSnapshot` is already merged and remains the canonical provider-independent nutrition truth.
- TNYX-113 remains the parent contract and explicitly defines `mode: detailed | manual`.
- TNYX-114 owns consumed-time/local-date/timezone policy; N20A-2 contains no time field and does not pre-empt it.
- TNYX-123 keeps barcode/provider capability, normalization, provenance and provider/legal review in a separate Backlog boundary; N20A-2 contains no provider field.
- MealLog physical persistence remains greenfield; this pure-Dart value contract requires no Supabase migration.
- No equivalent `N20A-2`, `MealLogMode`, or canonical MealLog-mode issue existed before focused TNYX-189 was created.

## 3. Locked Owner / Domain Decisions

### Meal name

```text
user enters meal name -> persist canonical mealName
blank meal name       -> mealName = null / absent
blank Quick Add record display fallback -> "Quick Log"
```

`Quick Log` is presentation fallback only and must never be fabricated persisted input. Older task-brief wording that says `Quick Add` is the blank saved-record fallback is stale and is not authority for future implementation.

### Capture source versus provider

```text
NutritionSnapshot     = canonical normalized nutrition truth
MealLogCaptureSource  = how the meal was initiated/captured
provider provenance   = where a specific structured item came from
```

Provider names such as FatSecret are never capture sources. Known provider origin remains a required later item-level capability, but exact `providerKey` / source-ID representation is deferred until the provider/item boundary is freshly audited.

Historical nutrition must never be silently recomputed by re-fetching mutable provider data.

## 4. Candidate Audit

### Candidate A — MealLogMode

**READY.** TNYX-113 already locks the semantic values `manual` and `detailed`. Explicit mode removes a real ambiguity: the durable mode must not be inferred from whether `detailedItems` happens to be empty. It requires no serving, provider, time, UI or database decision.

### Candidate B — provider/item provenance

**Deferred.** TNYX-123 still owns provider capability, normalized identity, provenance and provider/legal review. Freezing `providerKey`, `sourceFoodId`, `sourceServingId` or a speculative provenance wrapper now would pre-empt that audit and risks provider coupling.

## 5. Selected Slice — N20A-2

Owner: `apps/shared`.

```text
MealLogMode.manual   -> "manual"
MealLogMode.detailed -> "detailed"
unknown              -> null
```

Expected files:

```text
apps/shared/lib/src/nutrition/meal_log_mode.dart
apps/shared/lib/src/nutrition/nutrition.dart
apps/shared/test/nutrition/meal_log_mode_test.dart
```

Invariants:

- exactly two canonical identities;
- stable presentation-independent storage values;
- unknown/future serialized identity remains unknown and never falls back;
- mode is explicit domain identity, not derived from item count;
- no item, nutrition, provider, time, membership, ad or persistence data enters this type.

Deferred:

- aggregate-level `manualNutritionSnapshot` / `detailedItems` exclusivity enforcement;
- `MealLogEntry` and `MealLogItemSnapshot`;
- provider/item provenance;
- serving quantity/unit and normalization types;
- consumed-time/timezone policy;
- ID/version/delete/retry/concurrency semantics;
- Supabase persistence/repositories;
- Quick Add save and all UI/capture integrations.

## 6. Validation Plan

```text
dart format owned Dart files
dart analyze apps/shared
focused MealLogMode tests
full apps/shared tests
governed workspace analysis/tests
git diff --check
exact-head GitHub CI
```

Focused coverage: exactly two values, stable storage identities, round-trip, uniqueness, unknown/null decode, no fallback, distinct identities and deterministic enum semantics.

## 7. Adjacent Boundaries

- **TNYX-114:** time/date/timezone semantics remain separate; no time field in N20A-2.
- **TNYX-115:** Quick Add create/edit integration remains separate; no save wiring here.
- **TNYX-116:** idempotency/offline/concurrency remain separate.
- **TNYX-117:** integrated acceptance remains downstream.
- **Supabase:** no schema work in N20A-2.
- **Membership/ads:** never canonical MealLog-history truth; no fields here.

## 8. Gate Result

`READY — N20A-2 — Canonical MealLog mode value contract`

This readiness applies only to N20A-2. It is not readiness for the next provenance/item/aggregate/persistence slice. After PR #242 merges, run TNYX-66 again before any next TNYX-113 implementation.

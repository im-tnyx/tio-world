# TNYX-66 — N0 Nutrition pre-implementation audit & readiness gate

**Status:** Needs decision — post-PR-#242 refresh for the next TNYX-113 sub-slice
**Primary owner:** Nutrition architecture / `apps/shared` domain contracts
**Affected platforms:** Readiness/governance only; no implementation is authorised here

## Owner Approval and Scope Boundary

**Trigger:** None — read-only audit and focused task record.
**Approval status:** Audit only. No implementation is authorised by this refresh.
**Approval evidence:** Owner instruction of 2026-09-10 requested a TNYX-66 reconciliation against merged `main` after PR #242, preserving still-valid findings from an earlier local audit.
**Approved product/UI/data-shape boundaries:** None. Naming a candidate is not authorisation to build it.
**Explicit non-changes:** No MealLog source types, production Dart, runtime tests, implementation branch, Linear mutation, Supabase migration/mutation, Quick Add saving, provider integration, UI, PR merge, or branch deletion.

## Active Handoff

**Planning owner:** TNYX-66 readiness gate
**Implementation owner:** None — the previous sub-slices are merged and closed
**Review owner:** Owner
**Implementation ownership state:** Not started for the next slice
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-10
**Branch:** No implementation branch exists for the next slice. This reconciliation was produced in an isolated clean worktree based on `origin/main`.
**Base / main anchor:** `164ac6f5ac4b4ef87e5f4e9f81620fa124871f21`, squash merge of PR #242
**Observed working-tree state:** Reconciliation performed in an isolated worktree so unrelated protected local work in the primary checkout was never touched.
**Observed uncommitted/dirty files:** In the primary checkout only, and unrelated to this gate: protected modified root `pubspec.lock` and protected untracked `.ai/tasks/tnyx-54-nutrition-ia-readiness.md`.
**PR / tracker:** PR #241 and PR #242 are both **MERGED**. TNYX-188 **Done**, TNYX-189 **Done**, TNYX-187 **Done**, TNYX-54 **Done**. TNYX-66 remains **Backlog** and is still the active gate. TNYX-112/113/114/115/116/117 and TNYX-123 all remain **Backlog**. The only open PR is #237 and it touches `apps/core` only.
**Current implementation state:** `NutrientId`, `NutritionSnapshot`, `MealLogCaptureSource` and `MealLogMode` are all merged on `main` and exported from `apps/shared`. The MealLog aggregate, item snapshot, provider provenance, repositories and persistence remain unimplemented.
**Relevant execution surface:** `apps/shared/lib/src/nutrition`, `apps/shared/test/nutrition`
**Validation completed at SHA:** `164ac6f5` — read-only repository/GitHub/Linear inspection from a clean worktree.
**Validation remaining:** None for this gate.
**Current blocker:** No safe next sub-slice exists without one owner decision. See section 5.
**Open review finding IDs:** None
**Next exact action:** Owner picks one of the three unblocking decisions in section 5. Do not start any TNYX-113 implementation until then.

## 1. Current Readiness Question

What is the next smallest coherent and independently testable TNYX-113 implementation slice after the merged `MealLogCaptureSource` and `MealLogMode` contracts?

Result: **NEEDS DECISION.** Every remaining piece of the aggregate depends on an unresolved decision owned by another issue.

## 2. Current Repository / Dependency Evidence

Merged and verified on `main` at `164ac6f5`, all exported through `src/nutrition/nutrition.dart` → `shared.dart`:

```text
NutrientId            12 identities, stable storage values
NutritionSnapshot     missing != zero, negative/non-finite rejected, immutable
MealLogCaptureSource  9 identities incl. barcode, unknown -> null, no fallback
MealLogMode           manual | detailed, unknown -> null, no fallback
```

Persistence remains greenfield: 42 repository migrations, latest `20260909131518_enforce_meal_category_display_name_shape`, and no meal-log, food-log or diary-entry table or function. PR #241 and PR #242 added pure-Dart value contracts only.

## 3. Locked Owner / Domain Decisions

### Meal name

```text
user enters meal name -> persist canonical mealName
blank meal name       -> mealName = null / absent
blank Quick Add record display fallback -> "Quick Log"
```

`Quick Log` is a presentation fallback only and must never be persisted as fabricated user-entered `mealName`. Older task-brief wording naming `Quick Add` as the blank saved-record fallback is stale and is not authority for future implementation.

### Capture source versus provider versus nutrition

```text
NutritionSnapshot     = canonical normalized nutrition truth
MealLogCaptureSource  = how the meal was initiated/captured
provider provenance   = where a specific structured item came from
```

Provider names such as FatSecret are never capture sources. Known provider origin remains a required later item-level capability even when the UI never displays it, but the exact `providerKey` / source-ID representation is deferred until the provider/item boundary is freshly audited. Historical nutrition must never be silently recomputed by re-fetching mutable provider data.

## 4. Carried-Forward Audit Findings

Re-verified against `main` at `164ac6f5` and current Linear on 2026-09-10. These are reported, not applied. Do not mutate Linear or rewrite merged briefs from this gate.

### Tracker deltas — TNYX-113

| Item | Current wording | Correction |
|---|---|---|
| Capture-source list | Provenance section lists `text \| voice \| photo \| foodSearch \| recent \| savedMeal \| plannedMeal \| quickAdd` | `barcode` is missing. This now contradicts merged runtime, where `MealLogCaptureSource.barcode` exists. |
| `mealName` | Aggregate shows `mealName` without `?` | It is optional and persists as `null` when blank, per the locked decision above. |
| `sourceType` | `MealLogItemSnapshot` lists `sourceType` beside `providerKey` | Overlaps conceptually with the merged meal-level `MealLogCaptureSource`. The later item slice must decide whether item `sourceType` is a distinct concept or redundant. |

### Stale `Quick Add` fallback references

Superseded by the `Quick Log` decision, still present in merged briefs:

```text
.ai/tasks/tnyx-187-nutrition-snapshot.md:86        "display may derive `Quick Add`"
.ai/tasks/tnyx-188-meal-log-capture-source.md:202  "`Quick Add` may be used only as a UI display fallback"
```

Other `Quick Add` mentions in those files are legitimate entry-point or non-changes references and need no correction. TNYX-113 itself carries no display-fallback wording. Runtime carries none either: the `Quick Add` strings in `apps/features/nutrition` are entry-point titles, a semantic label and explanatory copy, not a blank-record fallback. Correcting the two merged briefs is a separate docs task.

### Stale documentation

| Doc | Issue |
|---|---|
| `.ai/CURRENT.md` | Last verified 2026-08-23; still an Onboarding O7 snapshot, not current Nutrition evidence |
| `.ai/DECISIONS.md` | D-012 and D-013 still marked `Target, not implemented` while Supabase is active infrastructure |
| `docs/DEVELOPMENT_SETUP.md` | Line 155 claims no Supabase workspace, project configuration or credential exists in this checkout; `supabase/` exists with 42 migrations |
| `docs/MODULE_OWNERSHIP.md`, `docs/ROADMAP.md`, `docs/SUPABASE_STRATEGY.md` | Retain future-`backend/` wording superseded by `AGENTS.md` and ADR-0007 |
| `.ai/tasks/tnyx-54-nutrition-ia-readiness.md` | Records 40 migrations, latest `20260907065602`; actual is 42, latest `20260909131518` |

None of these blocks this gate.

## 5. Candidate Audit For The Next Sub-Slice

### Candidate A — `MealLogEntry` aggregate — BLOCKED

Requires `consumedAt`, `consumedLocalDate` and timezone context. TNYX-114 owns that policy, is still Backlog, and its DST, ambiguous and nonexistent local-time rules are unresolved. Building the aggregate now would swallow TNYX-114 or invent timezone behavior.

### Candidate B — `MealLogItemSnapshot` — BLOCKED

Requires `quantity`, `servingUnit`, `normalizedAmount` and `normalizedUnit` typing, plus `sourceSnapshot` and `manualOverrides` shape. None is frozen. A snapshot without quantity and serving would be an incomplete, invalid type rather than a coherent slice.

### Candidate C — provider/item provenance — BLOCKED

TNYX-123 is still Backlog and owns provider capability, licensing, regional audit, normalized food identity, provenance and confidence fields, and states that no provider may be selected or integrated until readiness and provider/legal review pass. Freezing `providerKey`, `sourceFoodId` or `sourceServingId` now would pre-empt that audit and risk provider coupling.

### Candidate D — smaller residual contracts — NOT A SLICE

`mealCategoryId` is an existing feature-owned identifier and needs no new shared type. Repository convention for entity identity is a plain `String id`, as in `apps/shared/lib/src/workout/domain/models/training_session.dart`, so no ID value object is warranted. `mealName` length/normalization and `note` constraints are open data-shape decisions, not implementable slices. The manual/detailed exclusivity invariant is real but only testable once the aggregate exists.

### Conclusion

The two merged value contracts consumed the last pieces that were free of unresolved decisions. Nothing remains that both removes a real ambiguity and needs no external decision, so no slice should be invented merely to keep moving.

## 6. Required Owner Decision

Pick exactly one to unblock the next slice:

1. **Resolve TNYX-114 time semantics** — consumed-instant versus user-intended local date, timezone/offset retention, and DST ambiguous/nonexistent handling. Unblocks the `MealLogEntry` aggregate and is the shortest path to durable logging.
2. **Freeze serving and normalization typing** — `quantity`, `servingUnit`, `normalizedAmount`, `normalizedUnit`, plus `sourceSnapshot` and `manualOverrides` shape. Unblocks a coherent `MealLogItemSnapshot` core.
3. **Advance TNYX-123 provider identity representation** — how `providerKey` and source IDs are typed and where they attach. Unblocks item-level provenance.

Recommended first: option 1. TNYX-115 Quick Add create, TNYX-116 reliability and TNYX-117 acceptance all sit behind the aggregate, and manual-mode Quick Add needs neither serving typing nor provider identity.

## 7. Adjacent Boundaries

- **TNYX-114:** owns time/date/timezone semantics; unresolved and blocking Candidate A.
- **TNYX-115:** Quick Add create/edit integration remains separate; no save wiring authorised.
- **TNYX-116:** idempotency, offline retry and concurrency remain separate; a `version` field must not import concurrency semantics by itself.
- **TNYX-117:** integrated acceptance remains downstream.
- **TNYX-123:** owns provider/barcode contract; unresolved and blocking Candidate C.
- **Supabase:** persistence stays greenfield; physical schema remains a later slice with its own approval.
- **Membership/ads:** never canonical MealLog-history truth; no tier, ad-state or lifetime-cap field may enter the aggregate.
- **Identity:** new log gets a new id, edit keeps the same id, repeat from Recent creates a new id. Delete affects only the selected aggregate and never provider catalog, Saved Meal, Planned Meal or a source historical log.

## 8. Gate Result

`NEEDS DECISION — no remaining TNYX-113 sub-slice is free of an unresolved decision owned by TNYX-114, TNYX-123 or the open serving/normalization typing question.`

This gate authorises no implementation. After the owner resolves one of the three decisions in section 6, run TNYX-66 again before any TNYX-113 implementation starts.

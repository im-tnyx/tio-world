# TNYX-209 — Quick Add nutrition amount range & precision policy

**Status:** In progress — review finding open  
**Primary owner:** `apps/features/nutrition`  
**Affected platforms:** Flutter phone app (Quick Add / Quick Edit)

## Owner Approval and Scope Boundary

**Approval status:** `APPROVED`  
**Approval evidence:** Owner approved the audited V1 policy on 2026-09-13 and authorized implementation after TNYX-210 merged.  
**Approved boundary:** one shared manual/coarse Quick Add + Quick Edit validation policy for Calories, Carbs, Protein and Fat while preserving current editor geometry and interaction structure.  
**Explicit non-changes:** no Daily Nutrition Summary, Nutrition Targets behavior, detailed Meal Editor, AI text parsing, provider normalization policy, generic `NutritionSnapshot` narrowing, Supabase table/column shape change, schema migration, RLS change, serving/quantity model, TNYX-211 work, or visual redesign.

## Active Handoff

**Planning owner:** ChatGPT / owner-guided audit  
**Previous implementation owner:** ChatGPT — remote GitHub execution  
**Implementation owner:** none active; source edits paused during review  
**Review owner:** ChatGPT — remote GitHub review  
**Implementation ownership state:** Handoff pending — one P2 review finding is open; transfer implementation ownership before any source fix  
**Repository anchors:** `main@91b4eca3e3afae11c6f992179ce0555532f8c75c`; branch started at `7f893e9909332a72f8a26ef347721cf40d0aa84e`; reviewed source/handoff head `0403184f1c9ba7571200c675d16d068a3a0ad0c9`  
**Branch:** `tnyx/tnyx-209-n20c-3-quick-add-nutrition-amount-range-precision-policy`  
**PR:** #265 — `fix(nutrition): enforce Quick Add amount range and precision policy`  
**Tracker:** Linear `TNYX-209` — `In Review`  
**Current implementation state:** core V1 policy is implemented, but review found a raw-text precision edge that can bypass the locked <=1-decimal rule  
**Validation completed:** GitHub Actions run `34747527614` / `Analyze and test` succeeded on `0403184f1c9ba7571200c675d16d068a3a0ad0c9`; Flutter analyze, Dart analyze, Flutter tests and Dart tests all passed  
**Current blocker:** `TNYX-209-R1` (P2)  
**Open review finding IDs:** `TNYX-209-R1`  
**Next exact action:** transfer implementation ownership, reject excess raw fractional digits before numeric tolerance, add regression coverage, then rerun review + exact-head CI  

## Global UI / Design-System Guardrail

Root `AGENTS.md`, `apps/features/AGENTS.md`, and `apps/core/lib/src/theme/README.md` apply. TNYX-209 may change validation messages/enabled state only; it does not authorize geometry, spacing, typography, colors, input component geometry, or visual redesign.

## 1. Discovery

### User Outcome

A user cannot save absurdly large or over-precise manual nutrition values in Quick Add or Quick Edit, while legitimate zero values and missing optional nutrients retain their current meaning.

### Success Criteria

- One canonical manual/coarse amount policy is consumed by both create and edit paths.
- UI and controller/mutation validation agree.
- Invalid/non-finite/negative behavior remains blocked.
- Upper bounds prevent catastrophic typos from becoming durable meal truth.
- Precision is explicit and rejects excess user-entered fractional digits without silent rounding.
- `missing != zero`; optional missing macros stay missing.
- Existing out-of-policy rows remain readable but Quick Edit requires correction before a new save.

## 2. Owner-Locked V1 Policy

```text
Calories   min 0   max 10,000 kcal   precision <= 1 decimal
Carbs      min 0   max 1,000 g       precision <= 1 decimal
Protein    min 0   max 1,000 g       precision <= 1 decimal
Fat        min 0   max 1,000 g       precision <= 1 decimal
```

Locked behavior:

- explicit `0` is valid known zero;
- blank optional macros remain `null` / missing;
- excess precision is rejected, never silently rounded;
- existing out-of-policy rows remain readable but must be corrected before Quick Edit can save;
- above-max copy: `<Field> must be {max} or less.`;
- precision copy: `Use at most 1 decimal place.`;
- parse/non-finite copy: `Enter a number.`;
- negative copy: `<Field> cannot be negative.`;
- no DB/schema/RLS change in V1.

## 3. Architecture

```text
Quick Add / Quick Edit numeric text
        ↓
ManualNutritionAmountPolicy
        ├─ presentation error mapping
        └─ create/edit mutation validation
                ↓
ManualMealLogCreate / ManualMealLogUpdate
        ↓
MealLogRepository
```

The shared policy remains Nutrition-owned under `domain/usecases`. Generic `NutritionSnapshot`, DB constraints, Nutrition Targets and Core are intentionally unchanged.

## 4. Implementation Checklist

- [x] Audit current create/edit/widget/domain boundaries.
- [x] Owner approves exact V1 min/max/precision and copy.
- [x] Verify branch ancestry, task-only pre-implementation diff and Linear state.
- [x] Add one reusable manual/coarse amount policy under Nutrition ownership.
- [x] Make `QuickAddEditorSheet` and create/edit controllers consume the same policy.
- [x] Preserve optional `null`, explicit zero, hidden nutrients and retry/concurrency contracts.
- [x] Add policy, controller and widget boundary/precision coverage.
- [x] Add legacy out-of-policy Quick Edit correction regression.
- [x] Confirm no `NutritionSnapshot`, Nutrition Targets, TNYX-211, Core or Supabase/schema changes.
- [x] Exact-head CI succeeded on reviewed head `0403184f1c9ba7571200c675d16d068a3a0ad0c9`.
- [ ] Resolve `TNYX-209-R1`: raw text with more than one fractional digit must not pass because it is numerically close to a one-decimal value.
- [ ] Add a focused regression test for a near-step multi-decimal input such as `0.30000000009`.
- [ ] Re-run exact-head CI and review after the finding is fixed.

## 5. Quality Review

### Validation Evidence

```text
main / merge base = 91b4eca3e3afae11c6f992179ce0555532f8c75c
reviewed head = 0403184f1c9ba7571200c675d16d068a3a0ad0c9
changed files at reviewed head = 9 intended task/Nutrition paths
GitHub Actions run = 34747527614
check = Analyze and test
Flutter analyze = success
Dart analyze = success
Flutter tests = success
Dart tests = success
```

Green CI does not resolve the review finding because the current tests do not cover the near-step lexical precision case.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence / follow-up |
|---|---|---|---|---|---|
| TNYX-209-A1 | P1 | Resolved | Quick Add/Quick Edit accepted any finite non-negative amount; no shared upper-bound or precision policy existed. | `91b4eca3e3afae11c6f992179ce0555532f8c75c` | Shared policy + widget/create/edit enforcement and focused tests |
| TNYX-209-R1 | P2 | Open | `validateText()` parses before precision checking; the numeric tolerance can therefore accept raw multi-decimal text that is very close to a 0.1 step, e.g. `0.30000000009`, and persist it unchanged despite the locked <=1-decimal rule. | `0403184f1c9ba7571200c675d16d068a3a0ad0c9` | GitHub inline review `#pullrequestreview-5190238446`; validate raw fractional digits before applying numeric tolerance and add regression coverage |

## 6. Review Handoff

PR #265 is **not merge-ready** while `TNYX-209-R1` is open. No source fix was made during this review pass. Resolving the finding stays inside the already approved TNYX-209 scope, but implementation ownership must be explicitly reactivated before editing source.

Sequencing remains:

```text
resolve TNYX-209-R1
→ exact-head CI + review
→ TNYX-209 merge only with explicit owner instruction
→ post-merge sync per docs/POST_MERGE_SYNC.md
→ only then begin TNYX-205 when owner sequencing permits
```

### Final Status

`TNYX-209 REVIEW CHANGES REQUIRED`

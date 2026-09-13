# TNYX-209 — Quick Add nutrition amount range & precision policy

**Status:** Validated — final docs-only CI pending  
**Primary owner:** `apps/features/nutrition`  
**Affected platforms:** Flutter phone app (Quick Add / Quick Edit)

## Owner Approval and Scope Boundary

**Approval status:** `APPROVED`  
**Approval evidence:** Owner approved the V1 policy on 2026-09-13 and said `Go` to resolve review findings on PR #265.  
**Approved boundary:** one shared manual/coarse Quick Add + Quick Edit amount policy for Calories, Carbs, Protein and Fat; correctness fixes inside that policy are part of the same approved slice.  
**Explicit non-changes:** no Daily Nutrition Summary, Nutrition Targets, detailed Meal Editor, AI parsing, provider normalization, generic `NutritionSnapshot` narrowing, Supabase/schema/RLS changes, serving model, TNYX-211, TNYX-212 implementation, or visual redesign.

## Active Handoff

**Implementation owner:** inactive — source/test corrections complete and ownership released  
**Review owner:** ChatGPT / Codex — source review complete; final docs-only exact-head validation pending  
**Implementation ownership state:** Released after validated source/test head  
**Repository anchors:** exact base `main@91b4eca3e3afae11c6f992179ce0555532f8c75c`; branch start `7f893e9909332a72f8a26ef347721cf40d0aa84e`; R1 source fix `52b6f65dd1c7c4c97047bc3aaefcfbd5a6d597d7`; validated R2–R6 source/test head `68d3324328e6071bb3a2dfdbfd2ff766c771e090`  
**Branch:** `tnyx/tnyx-209-n20c-3-quick-add-nutrition-amount-range-precision-policy`  
**PR:** #265 — open, non-draft; ready for owner review only after this docs-only handoff commit receives exact-head green CI and metadata is reconciled  
**Tracker:** Linear `TNYX-209` — keep `In Progress` until final docs-only exact-head CI is green; then move to `In Review`; blocks TNYX-205 until explicit merge + post-merge sync  
**Open finding IDs:** none after this R7 handoff reconciliation  
**Validated source/test head:** `68d3324328e6071bb3a2dfdbfd2ff766c771e090`  
**Source validation:** GitHub Actions `34751982959` / #2483 passed Flutter analyze, Dart analyze, Flutter tests and Dart tests on exact source/test head `68d33243...`  
**Fresh Codex review:** exact source/test head `68d33243...` was reviewed by Codex (`PRR_kwDOTOXwB88AAAABNV_Rtg`); no new source/runtime P1/P2/P3 finding was produced. The only fresh P2 was `TNYX-209-R7`, this stale handoff reconciliation.  
**Next exact action:** exact-head CI for this docs-only handoff commit → verify no fresh actionable finding → resolve/reply review threads → reconcile PR + Linear to review-ready. Do not merge without explicit owner instruction.

## Owner-Locked V1 Policy

```text
Calories   min 0   max 10,000 kcal   precision <= 1 decimal
Carbs      min 0   max 1,000 g       precision <= 1 decimal
Protein    min 0   max 1,000 g       precision <= 1 decimal
Fat        min 0   max 1,000 g       precision <= 1 decimal
```

Locked behavior:

- explicit `0` is valid known zero;
- blank optional macros remain `null` / missing;
- excess precision is rejected, never silently rounded to make invalid user input valid;
- existing out-of-policy rows remain readable but must be corrected before Quick Edit can save;
- above-max copy: `<Field> must be {max} or less.`;
- precision copy: `Use at most 1 decimal place.`;
- parse/non-finite copy: `Enter a number.`;
- negative copy: `<Field> cannot be negative.`;
- no DB/schema/RLS change in V1.

## Architecture

```text
Quick Add / Quick Edit numeric text
        ↓ supported text format + lexical precision guard
ManualNutritionAmountPolicy
        ↓ ULP/magnitude-aware numeric grid + boundary validation
presentation + create/edit mutation controllers
        ↓
MealLogRepository
```

The shared policy remains Nutrition-owned under `domain/usecases`. UI geometry and Core contracts remain unchanged.

## Implemented Behavior

- raw scientific notation is rejected at the text boundary and cannot bypass the one-decimal policy;
- raw extra fractional digits remain rejected even when numerically close to a one-decimal grid point;
- direct numeric tiny non-zero values cannot inherit an absolute epsilon from the zero grid point; exact zero remains valid;
- ordinary IEEE-754 representation noise around a legitimate one-decimal grid point remains valid at macro and calorie magnitudes;
- bounded IEEE-754 noise at an exact approved maximum remains valid for direct numeric callers, while real above-maximum values remain rejected;
- accepted noisy durable values reopen as policy-compatible canonical editor text;
- invalid legacy values are not canonicalized into valid values and still block save until corrected;
- blank optional macros remain missing and explicit zero remains explicit zero;
- create and edit mutation boundaries consume the same shared policy;
- no product amount is rounded to make invalid user-entered text valid.

## Implementation Checklist

- [x] Initial shared amount policy + create/edit enforcement implemented.
- [x] `TNYX-209-R1` raw near-step precision gap fixed and regression-covered.
- [x] R2 scientific notation correction implemented with focused policy/widget coverage.
- [x] R3 accepted-noise Quick Edit hydration correction implemented with widget coverage.
- [x] R4 magnitude-aware numeric tolerance implemented with policy/controller coverage.
- [x] R5 zero-grid exactness correction implemented with policy/controller coverage.
- [x] R6 bounded max-boundary floating-point noise correction implemented.
- [x] R6 policy regressions cover noisy exact maxima and meaningful above-max values.
- [x] R6 create/edit controller regressions cover noisy exact maximum values.
- [x] Re-audited ancestry: exact merge base remains `main@91b4eca3...`; validated source branch was ahead and not behind.
- [x] Re-audited total PR scope: exactly 9 intended paths, task brief + `apps/features/nutrition/**` only.
- [x] Exact source/test head `68d33243...` passed GitHub Actions run `34751982959` / #2483.
- [x] Fresh independent review completed on `68d33243...` with no additional source/runtime finding.
- [x] Actual `@codex review` completed on reviewed commit `68d3324328`; no new source/runtime P1/P2/P3 finding; R7 was handoff-only.
- [x] R7 handoff reconciliation applied in this docs-only commit.
- [ ] Final docs-only handoff HEAD exact CI green.
- [ ] Reply to and resolve superseded/resolved review threads with exact evidence.
- [ ] Reconcile PR body and Linear; move Linear to `In Review` only when final exact-head CI is green and no actionable finding remains.

## Validation Evidence

### Historical R1

```text
source-fix SHA = 52b6f65dd1c7c4c97047bc3aaefcfbd5a6d597d7
GitHub Actions run = 34748286232
Flutter analyze = success
Dart analyze = success
Flutter tests = success
Dart tests = success
```

### R2–R4 intermediate validation

```text
source/test SHA = 3d0c4d287f957fb6c11fe04411fee93b63a0d0c8
GitHub Actions run = 34751101507 / #2475
Flutter analyze = success
Dart analyze = success
Flutter tests = success
Dart tests = success
```

### Final source/test validation through R6

```text
source/test SHA = 68d3324328e6071bb3a2dfdbfd2ff766c771e090
GitHub Actions run = 34751982959 / #2483
job = 103709989012
Flutter analyze = success
Dart analyze = success
Flutter tests = success
Dart tests = success
```

Package-level test totals are not inferred here; only tool-exposed stage conclusions are recorded.

### Scope at validated source/test head

- exact base / merge base: `main@91b4eca3e3afae11c6f992179ce0555532f8c75c`;
- exact source/test head: `68d3324328e6071bb3a2dfdbfd2ff766c771e090`;
- `behind_by = 0` at the source/test scope audit;
- exactly 9 intended changed paths;
- no Core, Supabase/schema/RLS, generic `NutritionSnapshot`, Nutrition Targets, TNYX-211/TNYX-212, lockfile or generated changes.

## Review Findings

| ID | Severity | Status | Finding | Observed at SHA | Resolution evidence |
|---|---|---|---|---|---|
| TNYX-209-A1 | P1 | Resolved | Quick Add/Quick Edit lacked shared upper-bound/precision policy. | `91b4eca3...` | Shared policy + UI/controller enforcement + focused tests |
| TNYX-209-R1 | P2 | Resolved | Raw/direct near-step value such as `0.30000000009` could pass tolerance. | `0403184f...` | Lexical guard + mutation numeric guard in `52b6f65d...`; exact CI `34748286232` green |
| TNYX-209-R2 | P2 | Resolved | Exponent-form raw input such as `1e-14` could bypass lexical precision. | `d73e723c...` | Exponent text rejected; policy/widget regressions; validated in `68d33243...` |
| TNYX-209-R3 | P2 | Resolved | Accepted FP noise could hydrate as long raw decimal and disable Quick Edit. | `d73e723c...` | Policy-approved canonical hydration for valid values; invalid legacy values stay unchanged; widget regression |
| TNYX-209-R4 | P2 | Resolved | Fixed absolute tolerance could reject valid one-decimal calorie-scale FP noise. | `d73e723c...` | ULP/magnitude-aware comparison + policy/controller regressions |
| TNYX-209-R5 | P2 | Resolved | Near-zero absolute epsilon could accept tiny non-zero direct values as zero noise. | `3d0c4d28...` | Zero grid point made exact; `1e-18` policy/controller regressions |
| TNYX-209-R6 | P2 | Resolved | Strict max range check could reject a mathematically exact maximum with ordinary binary overflow noise. | `e2db515b...` | Bounded max-boundary ULP handling in `fdb7910...`; policy/controller regressions through `68d33243...`; exact CI #2483 green |
| TNYX-209-R7 | P2 | Resolved by this handoff | Task brief still described R6 as pending after R6 implementation, regressions, exact-head CI and Codex review were complete. | `68d33243...` | This docs-only handoff reconciles owner state, checklist, findings and sequencing to validation/review-pending truth |

## Sequencing / Handoff

```text
this docs-only handoff commit
→ exact-head CI
→ verify no fresh actionable finding
→ reply/resolve review threads
→ PR + Linear reconciliation
→ Linear TNYX-209 In Review
→ owner review
→ merge only with explicit owner instruction
→ post-merge sync per docs/POST_MERGE_SYNC.md
→ only then begin TNYX-205
```

No merge is authorized by this handoff. `TNYX-212` remains separate future MealLog abuse-protection planning and is not part of this PR.

### Current Status

`TNYX-209 SOURCE VALIDATED / CODEX SOURCE REVIEW CLEAN — FINAL DOCS-ONLY CI PENDING`

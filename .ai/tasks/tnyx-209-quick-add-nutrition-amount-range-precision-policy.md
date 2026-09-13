# TNYX-209 — Quick Add nutrition amount range & precision policy

**Status:** In progress — Codex/re-review P2 corrections active  
**Primary owner:** `apps/features/nutrition`  
**Affected platforms:** Flutter phone app (Quick Add / Quick Edit)

## Owner Approval and Scope Boundary

**Approval status:** `APPROVED`  
**Approval evidence:** Owner approved the V1 policy on 2026-09-13 and said `Go` to resolve review findings on PR #265.  
**Approved boundary:** one shared manual/coarse Quick Add + Quick Edit amount policy for Calories, Carbs, Protein and Fat; correctness fixes inside that policy are part of the same approved slice.  
**Explicit non-changes:** no Daily Nutrition Summary, Nutrition Targets, detailed Meal Editor, AI parsing, provider normalization, generic `NutritionSnapshot` narrowing, Supabase/schema/RLS changes, serving model, TNYX-211, TNYX-212 implementation, or visual redesign.

## Active Handoff

**Implementation owner:** ChatGPT — active remote GitHub execution  
**Review owner:** paused while implementation ownership is active; Codex bot + ChatGPT re-review after validation  
**Implementation ownership state:** Active — bounded precision-policy corrections only  
**Repository anchors:** exact base `main@91b4eca3e3afae11c6f992179ce0555532f8c75c`; branch start `7f893e9909332a72f8a26ef347721cf40d0aa84e`; R1 source fix `52b6f65dd1c7c4c97047bc3aaefcfbd5a6d597d7`; Codex-reviewed head `d73e723cc1b32698cd0ccc7d3203cbba2d5d6a6c`  
**Branch:** `tnyx/tnyx-209-n20c-3-quick-add-nutrition-amount-range-precision-policy`  
**PR:** #265 — open, non-draft, not merge-ready while findings remain open  
**Tracker:** Linear `TNYX-209` — keep `In Progress`; blocks TNYX-205  
**Open finding IDs:** `TNYX-209-R2`, `TNYX-209-R3`, `TNYX-209-R4`, `TNYX-209-R5`, `TNYX-209-R6`  
**Latest source/test head before R6 fix:** `e2db515b85ffe695e40d63c1befbbb1cb74025d1`  
**Validation:** GitHub Actions `34751101507` / #2475 passed Flutter analyze, Dart analyze, Flutter tests and Dart tests on `3d0c4d28...`. Superseding R5 CI `34751594297` / #2479 was still running when Codex surfaced R6; it no longer completes the task because R6 requires a new source head.  
**Next exact action:** fix max-boundary floating-point noise handling, add focused regressions, run exact-head CI, then fresh independent + actual Codex bot review. Do not merge without explicit owner instruction.

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

## Correction Intent

- raw scientific notation cannot bypass the one-decimal text policy;
- direct numeric calls cannot bypass precision with tiny non-zero values;
- ordinary IEEE-754 representation noise around a legitimate one-decimal grid point remains valid at macro and calorie magnitudes;
- the same bounded floating-point noise must be accepted when a mathematically exact maximum lands microscopically above the binary maximum representation;
- real above-maximum values remain rejected;
- accepted noisy durable values reopen as an editable canonical representation;
- invalid legacy values are not canonicalized into valid values;
- meaningful extra precision such as `0.30000000009`, `999.99`, `8197.3000001`, or `1000.0000001` remains rejected.

## Implementation Checklist

- [x] Initial shared amount policy + create/edit enforcement implemented.
- [x] `TNYX-209-R1` raw near-step precision gap fixed and regression-covered.
- [x] R2 scientific notation correction implemented with focused policy/widget coverage.
- [x] R3 accepted-noise Quick Edit hydration correction implemented with widget coverage.
- [x] R4 magnitude-aware numeric tolerance implemented with policy/controller coverage.
- [x] R5 zero-grid exactness correction implemented with policy/controller coverage.
- [x] R2/R3/R4 source/test head `3d0c4d28...` passed exact-head CI run `34751101507` after lint-only test corrections.
- [ ] R6 accept only bounded IEEE-754 noise above the exact field maximum when the numeric value still represents that exact maximum grid point.
- [ ] Add R6 policy/create/edit regressions for `333.3 * 3 + 0.1 -> 1000.0000000000001` and prove meaningful above-max values still reject.
- [ ] Re-audit ancestry and 9-file scope after R6.
- [ ] Run exact-head CI after R6.
- [ ] Fresh independent review, then trigger/observe actual `@codex review` on the exact validated head.
- [ ] Reconcile task brief/PR/Linear to review-ready only when no actionable finding remains.

## Review Findings

| ID | Severity | Status | Finding | Observed at SHA | Resolution / required action |
|---|---|---|---|---|---|
| TNYX-209-A1 | P1 | Resolved | Quick Add/Quick Edit lacked shared upper-bound/precision policy. | `91b4eca3...` | Shared policy + UI/controller enforcement + tests |
| TNYX-209-R1 | P2 | Resolved | Raw/direct near-step value such as `0.30000000009` could pass tolerance. | `0403184f...` | Lexical precision guard + tighter numeric guard in `52b6f65d...` |
| TNYX-209-R2 | P2 | Open pending final re-review | Exponent-form raw input such as `1e-14` could bypass lexical precision. | `d73e723c...` | Current implementation rejects exponent notation; regression added |
| TNYX-209-R3 | P2 | Open pending final re-review | Accepted FP noise could hydrate as long raw decimal and disable Quick Edit. | `d73e723c...` | Valid stored amounts canonicalize for editor hydration; invalid legacy rows remain unchanged |
| TNYX-209-R4 | P2 | Open pending final re-review | Fixed absolute tolerance could reject valid one-decimal calorie-scale FP noise. | `d73e723c...` | Magnitude-aware epsilon/ULP comparison + regressions |
| TNYX-209-R5 | P2 | Open pending final re-review | Near zero, `max(1, magnitude)` created an absolute tolerance that could accept tiny non-zero direct values such as `1e-18` as zero noise. | `3d0c4d287f957fb6c11fe04411fee93b63a0d0c8` | Zero grid point is exact; direct tiny-value regressions added |
| TNYX-209-R6 | P2 | Open | Strict range validation runs before ULP precision validation, so a mathematically exact maximum can be rejected when binary arithmetic lands microscopically above it, e.g. `333.3 * 3 + 0.1 -> 1000.0000000000001`. | `e2db515b85ffe695e40d63c1befbbb1cb74025d1` | Apply the same bounded ULP/magnitude tolerance to the upper-bound comparison only when the value is effectively the exact maximum grid point; keep real above-max values rejected; add focused regressions |

## Sequencing

```text
resolve R6
→ exact-head CI
→ independent review + actual Codex bot review
→ resolve R2/R3/R4/R5/R6 only if clean
→ final docs-only handoff exact-head CI
→ Linear TNYX-209 In Review
→ merge only with explicit owner instruction
→ post-merge sync
→ only then TNYX-205
```

`TNYX-212` is separate future MealLog abuse-protection planning and is not part of this PR.

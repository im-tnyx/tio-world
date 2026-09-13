# TNYX-209 — Quick Add nutrition amount range & precision policy

**Status:** In progress — Codex P2 corrections active  
**Primary owner:** `apps/features/nutrition`  
**Affected platforms:** Flutter phone app (Quick Add / Quick Edit)

## Owner Approval and Scope Boundary

**Approval status:** `APPROVED`  
**Approval evidence:** Owner approved the audited V1 policy on 2026-09-13, authorized implementation after TNYX-210 merged, and said `Go` on 2026-09-13 to resolve the three fresh Codex P2 findings on PR #265.  
**Approved boundary:** one shared manual/coarse Quick Add + Quick Edit validation policy for Calories, Carbs, Protein and Fat while preserving current editor geometry and interaction structure. The three Codex findings are correctness corrections inside this already-approved slice, not new product scope.  
**Explicit non-changes:** no Daily Nutrition Summary, Nutrition Targets behavior, detailed Meal Editor, AI text parsing, provider normalization policy, generic `NutritionSnapshot` narrowing, Supabase table/column shape change, schema migration, RLS change, serving/quantity model, TNYX-211 work, or visual redesign.

## Active Handoff

**Planning owner:** ChatGPT / owner-guided audit  
**Previous implementation owner:** inactive after `TNYX-209-R1` handoff  
**Implementation owner:** ChatGPT — remote GitHub execution, reactivated for Codex P2 corrections  
**Review owner:** Codex bot / ChatGPT re-review after implementation; review role paused while source ownership is active  
**Implementation ownership state:** Active — bounded correction of three reviewed P2 findings only  
**Ownership transition:** Review/handoff -> Implementation owner on owner `Go`, 2026-09-13  
**Repository anchors:** `main@91b4eca3e3afae11c6f992179ce0555532f8c75c`; branch started at `7f893e9909332a72f8a26ef347721cf40d0aa84e`; R1 source-fix head `52b6f65dd1c7c4c97047bc3aaefcfbd5a6d597d7`; Codex-reviewed head `d73e723cc1b32698cd0ccc7d3203cbba2d5d6a6c`  
**Branch:** `tnyx/tnyx-209-n20c-3-quick-add-nutrition-amount-range-precision-policy`  
**PR:** #265 — open, non-draft, not merge-ready while `TNYX-209-R2/R3/R4` are open  
**Tracker:** Linear `TNYX-209` — keep `In Progress`; blocks `TNYX-205`  
**Current implementation state:** Base policy + R1 fix are implemented; three Codex precision/editability correctness findings require bounded correction  
**Current blockers:** `TNYX-209-R2`, `TNYX-209-R3`, `TNYX-209-R4`  
**Open review finding IDs:** `TNYX-209-R2`, `TNYX-209-R3`, `TNYX-209-R4`  
**Next exact action:** correct exponent-form parsing, preserve editability of numerically accepted floating-point noise on Quick Edit hydration, replace fixed absolute precision tolerance with a scale-aware comparison that still rejects meaningful over-precision; add focused regressions; run exact-head CI; re-review; reconcile PR/Linear/task brief only after validation  

## Global UI / Design-System Guardrail

Root `AGENTS.md`, `apps/features/AGENTS.md`, and `apps/core/lib/src/theme/README.md` apply. This correction may change only numeric text normalization/validation behavior necessary to preserve the locked policy. No production UI geometry, spacing, typography, colors, tokens, component size, sheet layout, or visual redesign is authorized.

## 1. Owner-Locked V1 Policy

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

## 2. Architecture

```text
Quick Add / Quick Edit numeric text
        ↓ strict supported text format + lexical precision guard
ManualNutritionAmountPolicy
        ↓ scale-aware numeric range + precision guard
presentation + create/edit mutation controllers
        ↓
MealLogRepository
```

The shared policy remains Nutrition-owned under `domain/usecases`. Generic `NutritionSnapshot`, DB constraints, Nutrition Targets and Core remain unchanged.

Correction intent:

- user-entered exponent/scientific notation must not bypass the one-decimal policy;
- values accepted at the direct numeric mutation boundary solely because they are ordinary binary floating-point representations of a one-decimal amount must remain editable when reopened in Quick Edit;
- numeric precision tolerance must scale with floating-point magnitude/ULP behavior rather than using one fixed absolute epsilon;
- meaningful extra precision such as the previously reviewed `0.30000000009` remains rejected;
- no product amount is silently rounded to make an invalid user-entered value valid.

## 3. Implementation Checklist

- [x] Initial TNYX-209 shared policy implemented for Calories/Carbs/Protein/Fat.
- [x] Quick Add widget and create/edit mutation controllers consume the same policy.
- [x] Preserve optional `null`, explicit zero, hidden nutrients, retry/idempotency and unchanged-time edit semantics.
- [x] Preserve current Quick Add geometry and governed `TioInput.numericEditor` surface.
- [x] `TNYX-209-R1` fixed and regression-covered.
- [x] Root/nested agent rules, theme README, live PR review and task brief reconciled before resuming source work.
- [x] Implementation ownership explicitly reactivated on owner `Go` for the three Codex findings.
- [ ] `TNYX-209-R2`: reject exponent/scientific-notation text that bypasses effective fractional precision.
- [ ] `TNYX-209-R3`: ensure numerically accepted binary-noise amounts hydrate into an editable Quick Edit representation without weakening raw user precision rejection.
- [ ] `TNYX-209-R4`: replace fixed numeric precision tolerance with a magnitude/ULP-aware comparison that accepts normal binary noise at calorie-scale values while rejecting meaningful excess precision.
- [ ] Add focused domain policy regressions for exponent forms, small values, magnitude-scale noise and meaningful excess precision.
- [ ] Add create/edit controller regressions for accepted/rejected numeric boundaries.
- [ ] Add Quick Edit widget regression proving an accepted noisy stored value reopens with Save enabled for an unrelated valid edit.
- [ ] Re-audit ancestry and changed paths.
- [ ] Run exact-source-head CI.
- [ ] Fresh Codex-style re-review after CI; record any new actionable findings before additional source work.
- [ ] Reconcile PR/Linear/task brief back to review-ready only when no open finding remains.

## 4. Quality Review

### Historical validation evidence

```text
main / merge base = 91b4eca3e3afae11c6f992179ce0555532f8c75c
R1 source-fix SHA = 52b6f65dd1c7c4c97047bc3aaefcfbd5a6d597d7
GitHub Actions run = 34748286232
job = 103700150801
Flutter analyze = success
Dart analyze = success
Flutter tests = success
Dart tests = success
```

This validation predates the three fresh Codex findings and does not validate their future fix HEAD. The later docs-only handoff run on `d73e723c...` was still queued when implementation ownership reopened and is no longer a completion gate for the superseding correction head.

Package-level test totals are not recorded because the available GitHub connector did not expose completed job logs; no test count is inferred or invented.

### Scope baseline before corrections

- `main@91b4eca3e3afae11c6f992179ce0555532f8c75c` is the exact merge base.
- Codex-reviewed head was `d73e723cc1b32698cd0ccc7d3203cbba2d5d6a6c`.
- PR changed-file set was exactly 9 intended paths: this task brief plus `apps/features/nutrition/**` only.
- no Core, Supabase/schema/RLS, generic `NutritionSnapshot`, Nutrition Targets, lockfile/generated, or TNYX-211 changes.

### Review findings

| ID | Severity | Status | Finding | Observed at SHA | Required resolution |
|---|---|---|---|---|---|
| TNYX-209-A1 | P1 | Resolved | Quick Add/Quick Edit accepted any finite non-negative amount; no shared upper-bound or precision policy existed. | `91b4eca3e3afae11c6f992179ce0555532f8c75c` | Shared policy + widget/create/edit enforcement and focused tests |
| TNYX-209-R1 | P2 | Resolved | Parsed tolerance could accept raw/direct near-step over-precision values such as `0.30000000009`. | `0403184f1c9ba7571200c675d16d068a3a0ad0c9` | Raw lexical guard + tighter numeric tolerance + regressions in `52b6f65d...` |
| TNYX-209-R2 | P2 | Open | Exponent-form input such as `1e-14` can avoid the raw decimal-point fractional digit check and may pass numeric tolerance. | `d73e723cc1b32698cd0ccc7d3203cbba2d5d6a6c` | Reject unsupported exponent-form raw input (or account for effective precision) and add regression coverage |
| TNYX-209-R3 | P2 | Open | A direct numeric amount accepted as normal FP noise (for example `0.1 + 0.2`) can hydrate as `0.30000000000000004`; raw lexical validation then disables Quick Edit even for unrelated edits. | `d73e723cc1b32698cd0ccc7d3203cbba2d5d6a6c` | Hydrate accepted numeric values to a canonical editable representation without weakening user-entered precision validation; add widget/edit regression |
| TNYX-209-R4 | P2 | Open | Fixed absolute precision tolerance can reject mathematically one-decimal calorie values at larger magnitudes, e.g. `8206.2 - 8.9 -> 8197.300000000001`. | `d73e723cc1b32698cd0ccc7d3203cbba2d5d6a6c` | Use magnitude/ULP-aware comparison and prove both normal-noise acceptance and meaningful over-precision rejection |

## 5. Handoff / Sequencing

PR #265 is **not merge-ready** while `TNYX-209-R2/R3/R4` are open. This correction does **not** authorize merge.

```text
resolve R2 + R3 + R4
→ exact-head CI
→ fresh Codex-style review
→ Linear TNYX-209 In Review only if clean
→ merge only with explicit owner instruction
→ post-merge sync per docs/POST_MERGE_SYNC.md
→ only then begin TNYX-205
```

### Current Status

`TNYX-209 CODEX P2 CORRECTIONS ACTIVE`

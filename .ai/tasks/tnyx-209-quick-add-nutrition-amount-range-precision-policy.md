# TNYX-209 — Quick Add nutrition amount range & precision policy

**Status:** Validated — ready for review  
**Primary owner:** `apps/features/nutrition`  
**Affected platforms:** Flutter phone app (Quick Add / Quick Edit)

## Owner Approval and Scope Boundary

**Approval status:** `APPROVED`  
**Approval evidence:** Owner approved the audited V1 policy on 2026-09-13 and authorized implementation after TNYX-210 merged.  
**Approved boundary:** one shared manual/coarse Quick Add + Quick Edit validation policy for Calories, Carbs, Protein and Fat while preserving current editor geometry and interaction structure.  
**Explicit non-changes:** no Daily Nutrition Summary, Nutrition Targets behavior, detailed Meal Editor, AI text parsing, provider normalization policy, generic `NutritionSnapshot` narrowing, Supabase table/column shape change, schema migration, RLS change, serving/quantity model, TNYX-211 work, or visual redesign.

## Active Handoff

**Planning owner:** ChatGPT / owner-guided audit  
**Implementation owner:** Inactive — implementation and `TNYX-209-R1` resolution complete  
**Review owner:** ChatGPT — remote re-review complete; no open actionable finding  
**Implementation ownership state:** Released to review/handoff  
**Repository anchors:** `main@91b4eca3e3afae11c6f992179ce0555532f8c75c`; branch started at `7f893e9909332a72f8a26ef347721cf40d0aa84e`; R1 source-fix head `52b6f65dd1c7c4c97047bc3aaefcfbd5a6d597d7`  
**Branch:** `tnyx/tnyx-209-n20c-3-quick-add-nutrition-amount-range-precision-policy`  
**PR:** #265 — open; ready for review after this docs-only handoff commit receives exact-head green CI  
**Tracker:** Linear `TNYX-209`; transition to `In Review` after final exact-head CI succeeds  
**Current implementation state:** Complete within the approved TNYX-209 scope  
**Current blocker:** none  
**Open review finding IDs:** none  
**Next exact action:** verify exact-head CI for this final docs-only handoff commit, then reconcile PR + Linear to review-ready state; do not merge without explicit owner instruction  

## Global UI / Design-System Guardrail

Root `AGENTS.md` and `apps/features/AGENTS.md` apply. TNYX-209 changes validation policy/error state only; no production UI geometry, spacing, typography, colors, tokens, input component geometry, or visual redesign were changed.

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
        ↓ raw lexical precision guard
ManualNutritionAmountPolicy
        ↓ numeric range + precision guard
presentation + create/edit mutation controllers
        ↓
MealLogRepository
```

The shared policy remains Nutrition-owned under `domain/usecases`. Generic `NutritionSnapshot`, DB constraints, Nutrition Targets and Core remain unchanged.

`TNYX-209-R1` hardened precision at both boundaries:

- raw text rejects more than one fractional digit before floating-point tolerance can mask it;
- parsed/direct controller values use a tighter tolerance that still accepts ordinary binary representation noise such as `0.1 + 0.2` while rejecting the reviewed bypass example `0.30000000009`;
- no value is rounded or quantized before persistence.

## 3. Implementation Checklist

- [x] Initial TNYX-209 shared policy implemented for Calories/Carbs/Protein/Fat.
- [x] Quick Add widget and create/edit mutation controllers consume the same policy.
- [x] Preserve optional `null`, explicit zero, hidden nutrients, retry/idempotency and unchanged-time edit semantics.
- [x] Preserve current Quick Add geometry and governed `TioInput.numericEditor` surface.
- [x] Review found and recorded `TNYX-209-R1` before merge.
- [x] Root/nested agent rules, task brief, PR and Linear state reconciled before resuming source work.
- [x] Reject raw text with more than one fractional digit before numeric tolerance.
- [x] Reject direct numeric/controller near-step `0.30000000009` while ordinary computed `0.1 + 0.2` remains valid.
- [x] Add focused policy regression coverage.
- [x] Add create/edit controller bypass regression coverage.
- [x] Add widget regression coverage for locked precision copy and disabled CTA.
- [x] Re-audit ancestry and changed paths.
- [x] Exact-source-head CI passed on `52b6f65dd1c7c4c97047bc3aaefcfbd5a6d597d7`.
- [x] Re-review completed and GitHub `TNYX-209-R1` inline thread resolved after validation.
- [ ] Final docs-only handoff HEAD exact CI pending at commit creation time.
- [ ] Move Linear to `In Review` only after that final exact-head CI succeeds.

## 4. Quality Review

### Validation evidence

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

Package-level test totals are not recorded here because the available GitHub connector did not expose completed job logs; no test count is inferred or invented.

### Final scope audit at source-fix head

- `main` remains the exact merge base.
- branch was ahead 9 / behind 0 before this final handoff commit.
- PR changed-file set remains exactly 9 intended paths: this task brief plus `apps/features/nutrition/**` only.
- no Core, Supabase/schema/RLS, generic `NutritionSnapshot`, Nutrition Targets, lockfile/generated, or TNYX-211 changes.

### Review findings

| ID | Severity | Status | Finding | Observed at SHA | Evidence / resolution |
|---|---|---|---|---|---|
| TNYX-209-A1 | P1 | Resolved | Quick Add/Quick Edit accepted any finite non-negative amount; no shared upper-bound or precision policy existed. | `91b4eca3e3afae11c6f992179ce0555532f8c75c` | Shared policy + widget/create/edit enforcement and focused tests |
| TNYX-209-R1 | P2 | Resolved | Parsed tolerance could accept raw/direct near-step over-precision values such as `0.30000000009`. | `0403184f1c9ba7571200c675d16d068a3a0ad0c9` | Raw lexical precision guard + tighter numeric tolerance + policy/controller/widget regressions in `52b6f65dd1c7c4c97047bc3aaefcfbd5a6d597d7`; exact-source-head CI green; inline review thread replied to and resolved |

## 5. Handoff / Sequencing

TNYX-209 source implementation and R1 correction are complete. This handoff does **not** authorize merge.

```text
final docs-only exact-head CI
→ Linear TNYX-209 In Review + PR metadata reconciliation
→ owner review / merge only with explicit instruction
→ post-merge sync per docs/POST_MERGE_SYNC.md
→ only then begin TNYX-205
```

### Current Status

`TNYX-209 READY FOR REVIEW — FINAL CI PENDING`

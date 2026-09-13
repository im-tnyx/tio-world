# TNYX-209 — Quick Add nutrition amount range & precision policy

**Status:** In progress — `TNYX-209-R1` fix active  
**Primary owner:** `apps/features/nutrition`  
**Affected platforms:** Flutter phone app (Quick Add / Quick Edit)

## Owner Approval and Scope Boundary

**Approval status:** `APPROVED`  
**Approval evidence:** Owner approved the audited V1 policy on 2026-09-13 and authorized implementation after TNYX-210 merged.  
**Approved boundary:** one shared manual/coarse Quick Add + Quick Edit validation policy for Calories, Carbs, Protein and Fat while preserving current editor geometry and interaction structure.  
**Explicit non-changes:** no Daily Nutrition Summary, Nutrition Targets behavior, detailed Meal Editor, AI text parsing, provider normalization policy, generic `NutritionSnapshot` narrowing, Supabase table/column shape change, schema migration, RLS change, serving/quantity model, TNYX-211 work, or visual redesign.

## Active Handoff

**Planning owner:** ChatGPT / owner-guided audit  
**Previous implementation owner:** ChatGPT — remote GitHub execution, paused for review  
**Implementation owner:** ChatGPT — remote GitHub execution, reactivated for `TNYX-209-R1`  
**Review owner:** ChatGPT — review pass completed; review role paused while implementation ownership is active  
**Implementation ownership state:** Active — review finding resolution only  
**Ownership transition:** Review owner -> Implementation owner on owner `Go`, 2026-09-13; same approved TNYX-209 slice, no new product approval required  
**Repository anchors:** `main@91b4eca3e3afae11c6f992179ce0555532f8c75c`; branch started at `7f893e9909332a72f8a26ef347721cf40d0aa84e`; reviewed source/handoff head `0403184f1c9ba7571200c675d16d068a3a0ad0c9`; pre-fix review-record head `75aff118fe0151540165a4827959626f6547f072`  
**Branch:** `tnyx/tnyx-209-n20c-3-quick-add-nutrition-amount-range-precision-policy`  
**PR:** #265 — open, not merge-ready while `TNYX-209-R1` is open  
**Tracker:** Linear `TNYX-209` — `In Progress`; blocks `TNYX-205`  
**Current implementation state:** V1 policy is implemented; one raw-text/numeric near-step precision edge remains to fix  
**Validation completed:** GitHub Actions run `34747527614` succeeded on reviewed head `0403184f1c9ba7571200c675d16d068a3a0ad0c9`; this is historical evidence only because HEAD has moved  
**Current blocker:** `TNYX-209-R1` (P2)  
**Open review finding IDs:** `TNYX-209-R1`  
**Next exact action:** reject excess raw fractional digits before parsing, tighten numeric tolerance enough to block direct-controller near-step bypass while preserving normal binary noise, add focused policy/controller/widget regressions, then exact-head CI and re-review  

## Global UI / Design-System Guardrail

Root `AGENTS.md` and `apps/features/AGENTS.md` apply. The R1 fix is domain validation + regression coverage only; no production UI geometry, tokens, copy, or layout changes are authorized.

## 1. User Outcome

A user cannot save absurdly large or over-precise manual nutrition values in Quick Add or Quick Edit, while legitimate zero values and missing optional nutrients retain their current meaning.

Success requires:

- one canonical manual/coarse amount policy consumed by UI and create/edit mutation boundaries;
- invalid/non-finite/negative/out-of-range/over-precise values blocked;
- user-entered raw text with more than one fractional digit rejected exactly, not accepted because it is numerically close to a one-decimal step;
- direct numeric/controller calls unable to bypass the same precision intent except ordinary floating-point representation noise;
- `missing != zero` preserved;
- existing out-of-policy rows readable but unsaveable until corrected.

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
        ↓ raw lexical precision guard
ManualNutritionAmountPolicy
        ↓ numeric range + precision guard
presentation + create/edit mutation controllers
        ↓
MealLogRepository
```

The shared policy remains Nutrition-owned under `domain/usecases`. Generic `NutritionSnapshot`, DB constraints, Nutrition Targets and Core remain unchanged.

## 4. Implementation Checklist

- [x] Initial TNYX-209 policy implemented and validated on reviewed head.
- [x] Review found and recorded `TNYX-209-R1`.
- [x] Root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/tasks/README.md`, live PR and Linear state reconciled before resuming source work.
- [x] Implementation ownership explicitly reactivated for the same approved slice.
- [ ] Reject raw text with more than one fractional digit before numeric tolerance.
- [ ] Ensure direct numeric/controller near-step values such as `0.30000000009` are rejected while ordinary computed `0.1 + 0.2` remains valid.
- [ ] Add focused policy regression coverage.
- [ ] Add controller bypass regression coverage.
- [ ] Add widget regression coverage for the exact locked precision copy / CTA gate.
- [ ] Re-audit changed paths and ancestry.
- [ ] Run exact-head CI.
- [ ] Re-review and resolve GitHub review thread only after applicable validation passes.
- [ ] Reconcile Linear/PR/task brief to `In Review` only when no open finding remains.

## 5. Quality Review

### Historical validation evidence

```text
main / merge base = 91b4eca3e3afae11c6f992179ce0555532f8c75c
reviewed head = 0403184f1c9ba7571200c675d16d068a3a0ad0c9
GitHub Actions run = 34747527614
Flutter analyze = success
Dart analyze = success
Flutter tests = success
Dart tests = success
```

This evidence predates `TNYX-209-R1` resolution and cannot validate the current/future fix HEAD.

### Review findings

| ID | Severity | Status | Finding | Observed at SHA | Evidence / follow-up |
|---|---|---|---|---|---|
| TNYX-209-A1 | P1 | Resolved | Quick Add/Quick Edit accepted any finite non-negative amount; no shared upper-bound or precision policy existed. | `91b4eca3e3afae11c6f992179ce0555532f8c75c` | Shared policy + widget/create/edit enforcement and focused tests |
| TNYX-209-R1 | P2 | Open | `validateText()` parses before precision checking; tolerance can accept raw multi-decimal near-step values such as `0.30000000009`; the same tolerance can also permit a direct numeric controller call with that value. | `0403184f1c9ba7571200c675d16d068a3a0ad0c9` | Unresolved GitHub inline review thread on `manual_nutrition_amount_policy.dart`; fix + regression + exact-head CI + re-review required |

## 6. Handoff / Sequencing

PR #265 is **not merge-ready** while `TNYX-209-R1` is open. Do not merge without explicit owner instruction.

```text
resolve TNYX-209-R1
→ exact-head CI + re-review
→ Linear TNYX-209 In Review
→ merge only with explicit owner instruction
→ post-merge sync per docs/POST_MERGE_SYNC.md
→ only then begin TNYX-205
```

### Current Status

`TNYX-209 R1 IMPLEMENTATION ACTIVE`

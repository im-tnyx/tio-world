# TNYX-191 — Meal-level note contract for manual MealLog persistence

**Status:** Review-ready — implementation and exact-head validation complete; merge not authorized
**Primary owner:** `apps/shared` Nutrition domain
**Affected platforms:** Shared Dart only

## Owner Approval and Scope Boundary

**Approval status:** Approved for the pre-migration domain slice.
**Approval evidence:** Owner explicitly instructed the post-TNYX-190 persistence audit to continue and stated that any Supabase migration requires a separate later approval. During implementation the owner clarified that the current aggregate/persistence work should follow the real Quick Log/manual flow only; fields needed by later logging flows are added when those flows become implementation-ready.
**Approved scope:** canonical `MealLogEntry.note` field + manual factory behavior + focused tests + readiness evidence.
**Explicit non-changes:** no Supabase migration/schema/RLS/grants/index change, no repository/DTO/PostgREST wiring, no UI/navigation, no detailed-mode construction, no item snapshots, no photo/provider provenance, no idempotency/concurrency/version work.

## Fresh Audit Evidence — 2026-09-11

- Base `main`: `1d67599a33d06978f476e34152153bb5bcbe3927` (PR #247 merge).
- Hosted Supabase project `tio-world` is healthy on Postgres 17 and currently has no MealLog table.
- Hosted migration ledger has 42 migrations; latest is `20260909131518_enforce_meal_category_display_name_shape`.
- Current owner-scoped history precedent `body_weight_logs` uses UUID PK, `user_id -> public.users(id) ON DELETE CASCADE`, `timestamptz`, `set_row_updated_at()`, own-row verb RLS and `(user_id, measured_at DESC)` indexing.
- Existing project default table privileges are broad; a later MealLog migration must explicitly audit and lock intended Data API grants instead of assuming inherited defaults are correct.
- Canonical manual `MealLogEntry` already owns id/user/mode/category/name/consumed instant/local date/time context/capture source/manual nutrition/created/updated.
- TNYX-68 defines `MealLogEntry.note` as actual-log data independent from the Meal Notes visibility preference and requires hidden-note preservation.
- TNYX-115 includes optional note in Quick Add create/edit semantics.
- TNYX-113 and TNYX-58 also describe future optional meal photo/provenance/detailed-item fields, but those are not required by the current Quick Log/manual flow and their real media/item contracts are not yet frozen.
- Therefore the current slice adds only the note needed by manual Quick Log. Future flows may widen the same canonical `MealLogEntry` additively after their own audits; no parallel manual-only aggregate/table should be created.

## Locked Note Semantics

- `note` is nullable actual-history data on `MealLogEntry`.
- Null or whitespace-only input becomes `null`.
- Nonblank text is preserved exactly; this domain slice does not trim, collapse, truncate or rewrite user text.
- Meal Notes OFF is a presentation/capability state only. A caller that does not expose note editing must preserve the existing note rather than sending an intentional clear.
- No arbitrary note length limit is invented in this slice.

## Future-field Guardrail

Current manual/Quick Log work must not pre-freeze fields whose real consumers are later flows.

```text
Quick Log/manual now
→ note + manualNutritionSnapshot + current meal/time/category fields

Later detailed/photo/provider flows
→ add photo/media reference, detailed item snapshots and richer provenance
→ only after those contracts are audited and approved
```

In particular, do not add a placeholder `photoRef` string merely because TNYX-113 names that conceptual field. A future Meal Editor/photo slice must first lock the private-media identity/lifecycle it actually needs.

## Implementation

- [x] Add `note` to the private canonical aggregate constructor.
- [x] Add optional `note` parameter to `MealLogEntry.manual`.
- [x] Normalize null/whitespace-only to absent while preserving nonblank text exactly.
- [x] Add focused tests for null, blank and exact nonblank preservation.
- [x] Run implementation-head Flutter CI #2362 — SUCCESS on `5c1c5d05d732d4345cf35ccdeb9aa28342b32070`.
- [x] Manual exhaustive diff review — PASS, no findings.
- [x] Reconcile this active handoff to current state.
- [x] Run final exact-head Flutter CI #2363 — SUCCESS on docs-only final head before review-ready transition.

## Changed Files

```text
.ai/tasks/tnyx-191-meal-log-note-contract.md
apps/shared/lib/src/nutrition/meal_log_entry.dart
apps/shared/test/nutrition/meal_log_entry_test.dart
```

## Review-ready Evidence

- PR: #248 `feat(shared): add manual MealLog note contract`.
- Branch: `tnyx/tnyx-191-n20a-4-meal-level-note-contract-for-manual-meallog`.
- Base remains audited `main` `1d67599a33d06978f476e34152153bb5bcbe3927`.
- Scope audit before final handoff: 5 commits ahead / 0 behind, exactly 3 changed files.
- CI #2362: full analyze + Flutter tests + Dart tests SUCCESS.
- CI #2363: full analyze + Flutter tests + Dart tests SUCCESS on the final docs-only checkpoint head.
- Manual review: PASS, no open findings.
- Supabase: no migration/schema/RLS/grant/index write performed.
- Merge: intentionally not performed without separate owner instruction.

## Migration Gate

After this domain slice is merged, re-audit and present the proposed manual `public.meal_log_entries` physical contract to the owner. Do **not** create or apply a Supabase migration until the owner explicitly approves that migration.

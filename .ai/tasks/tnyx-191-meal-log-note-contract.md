# TNYX-191 — Meal-level note contract for manual MealLog persistence

**Status:** In progress — domain-only pre-migration slice
**Primary owner:** `apps/shared` Nutrition domain
**Affected platforms:** Shared Dart only

## Owner Approval and Scope Boundary

**Approval status:** Approved for the pre-migration domain slice.
**Approval evidence:** Owner explicitly instructed the post-TNYX-190 persistence audit to continue and stated that any Supabase migration requires a separate later approval.
**Approved scope:** canonical `MealLogEntry.note` field + manual factory behavior + focused tests + readiness evidence.
**Explicit non-changes:** no Supabase migration/schema/RLS/grants/index change, no repository/DTO/PostgREST wiring, no UI/navigation, no detailed-mode construction, no item snapshots, no photo/provider provenance, no idempotency/concurrency/version work.

## Fresh Audit Evidence — 2026-09-11

- Base `main`: `1d67599a33d06978f476e34152153bb5bcbe3927` (PR #247 merge).
- Hosted Supabase project `tio-world` is healthy on Postgres 17 and currently has no MealLog table.
- Hosted migration ledger has 42 migrations; latest is `20260909131518_enforce_meal_category_display_name_shape`.
- Current owner-scoped history precedent `body_weight_logs` uses UUID PK, `user_id -> public.users(id) ON DELETE CASCADE`, `timestamptz`, `set_row_updated_at()`, own-row verb RLS and `(user_id, measured_at DESC)` indexing.
- Existing project default table privileges are still broad for `anon`/`authenticated`/`service_role`; a later MealLog migration must explicitly revoke/grant intended Data API privileges rather than inheriting defaults.
- Supabase 2026 platform direction also moves public-table Data API exposure to explicit grants. Migration work remains unapproved.
- Canonical manual `MealLogEntry` already owns id/user/mode/category/name/consumed instant/local date/time context/capture source/manual nutrition/created/updated.
- TNYX-68 defines `MealLogEntry.note` as actual-log data independent from the Meal Notes visibility preference and requires hidden-note preservation.
- TNYX-115 includes optional note in Quick Add create/edit semantics.
- Therefore physical manual persistence should not be frozen before the aggregate can carry the note it is required to preserve.

## Locked Note Semantics

- `note` is nullable actual-history data on `MealLogEntry`.
- Null or whitespace-only input becomes `null`.
- Nonblank text is preserved exactly; this domain slice does not trim, collapse, truncate or rewrite user text.
- Meal Notes OFF is a presentation/capability state only. A caller that does not expose note editing must preserve the existing note rather than sending an intentional clear.
- No arbitrary note length limit is invented in this slice.

## Implementation

- [ ] Add `note` to the private canonical aggregate constructor.
- [ ] Add optional `note` parameter to `MealLogEntry.manual`.
- [ ] Normalize null/whitespace-only to absent while preserving nonblank text exactly.
- [ ] Add focused tests for null, blank and nonblank/multiline preservation.
- [ ] Run exact-head CI and manual review.

## Migration Gate

After this domain slice is merged, re-audit and present the proposed manual `public.meal_log_entries` physical contract to the owner. Do **not** create or apply a Supabase migration until the owner explicitly approves that migration.

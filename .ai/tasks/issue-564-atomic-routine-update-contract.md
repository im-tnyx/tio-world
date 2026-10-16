# GitHub #564 — Atomic Routine Name + Composition Update contract

**Status:** In progress — contract/security design only; implementation and deployment gated
**Primary owner:** Workout + Supabase architecture
**Affected platforms:** Flutter phone, Supabase Postgres; no watch/AI/server app

## Owner Approval and Scope Boundary

**Trigger:** Owner-approved follow-on from UI-only PR #570: 2026-10-16 “Go” after Name+composition audit; Routine Rename belongs in the existing shared Edit composer.
**Approval status:** Contract/security investigation approved. Implementation that changes existing Supabase column semantics, table/column shapes, or unapproved visible UI remains gated by explicit scoped approval; do not interpret a “Go” as blanket production deployment approval.
**Approved product boundary:** design one owner-safe atomic Update of saved Routine Name and Exercise/Set composition without duplicating Create/Edit UI.
**Explicit non-changes:** No SQL migrations/deployments, table/column changes, grants/RLS changes, Flutter UI/routing changes, Delete, Move, Note, Rest, performed history, Workout Settings or service/API infrastructure in this contract-only slice.

## Active Handoff

**Planning owner:** GitHub #564 + Linear TNYX-81 (Backlog, blocked by TNYX-78/TNYX-80)
**Implementation owner:** Current GitHub-connected session; contract/docs branch only. No competing open Routine atomic-update PR found.
**Review owner:** Independent Codex reviewer on Draft PR.
**Ownership transition:** New gated child slice after merged PR #570. Prior `.ai/tasks/issue-564-routine-ui-parity.md` is a historical pre-merge snapshot and must not be treated as a live branch.
**Repository state last verified:** GitHub `main@ca02216936e146e9b0553e440d91b777c24d4d25` (2026-10-16), after merged PRs #570, #573 and #574. Owner's last local PowerShell checkout was `7f05def9`; local Windows worktree not inspectable here and must be re-synced separately before local source work.
**Branch:** `tnyx/issue-564-atomic-routine-update-contract`
**HEAD SHA:** Refresh from GitHub after each commit; contract branch initially forked at `ca022169`.
**Observed working-tree state:** GitHub-hosted branch only; no claim about Windows dirty/untracked state.
**PR / tracker:** GitHub #564 open, Linear TNYX-81 Backlog, related Delete GitHub #526.
**Current implementation state:** Contract proposal, **zero production source changes**.
**Validation completed:** Source inspection and live *read-only* Supabase schema/function/grant/trigger queries, details below. No local SQL replay/Flutter tests claimed.
**Validation remaining:** Independent contract review; decision on legacy rename race/semantic migration; SQL concurrency/RLS regression design approval before implementing.
**Current blocker:** Legacy authenticated Data API `UPDATE(name)` does not bump `composition_revision` or clear `last_composition_mutation_id`, so a new combined RPC cannot promise stale-name safety while old clients remain unrestricted.
**Open review findings:** Codex exact-head `7ed01fdf` reported two P1 items, `PRRT_kwDOTOXwB86tJ6Vj` (same-token replay must precede stale CAS) and `PRRT_kwDOTOXwB86tJ6Vq` (rollback-safe DB/client compatibility rollout). Both accepted; documentation remediation pending independent re-review.
**Next exact action:** Verify Codex replay-order and rollout P1 corrections at the new exact HEAD; disposition review threads with source evidence. Decide legacy-client compatibility/column-semantic approval before a separate implementation slice. No merge or deploy of this documentation PR without separate approval.

## 1. Discovery

**User outcome:** One Edit Routine page preloads saved name and ordered Exercises/Sets, and **one** Update can commit either or both atomically. Routine cards will later route overflow Edit into this exact shared composer.

**Success:** Name-only leaves Sets untouched; composition-only leaves Name untouched; combined edit is all-or-nothing; stale/conflicting operations fail honestly; retries cannot duplicate or misreport changes.

**Non-goals:** No direct replacement of 3-dot Rename now, no enabled Delete, no published app release claim.

## 2. Codebase Exploration — checked evidence

- `RoutineRepository.rename` / `SupabaseRoutineTableGateway.renameRow`: separate owner-filtered Data API `UPDATE(name)`, and `ProgramRoutinesController.rename` uses post-write owner read.
- `RoutineCompositionSave` and `SupabaseRoutineCompositionGateway.save`: existing 4-parameter `public.save_user_workout_routine_composition(uuid,bigint,uuid,jsonb)`; revision, mutation UUID and Exercise/Set snapshot, **no Name**.
- `RoutineEditorController` stores only composition `_baseline/_draft`, calls owner Routine list and revision-validated composition read separately, shortcuts no-change Update, and reconciles uncertainty against Sets only.
- `EditRoutinePage` does not include Name field; shared `RoutineComposerScreen` is already used by Create/Edit. `ProgramDetailPage._openRename` still shows `_RoutineNameSheet`.
- Latest checked-in RPC: `supabase/migrations/20261015180000_guard_routine_custom_type_at_save.sql` (SECURITY DEFINER, empty search_path, auth.uid owner check, parent FOR UPDATE, legacy rich-set protection, archived/type-change guard, 256KiB payload bound, revision/mutation, no Name mutation).
- Live Tio-world Supabase project `oykupyiitspujzpwwvuj` **queried read-only** on 2026-10-16: exactly eight `user_workout_routines` columns incl. `name`, `composition_revision`, `last_composition_mutation_id`; authenticated has SELECT/INSERT and UPDATE(**name**) only. Four-argument composition RPC and five-argument Create RPC are SECURITY DEFINER and authenticated-only, not anon. Parent has ONLY `trg_user_workout_routines_updated_at`, which updates timestamp and **does not increment revision for direct Rename**. Hosted migration ledger ends in `20261015180000_guard_routine_custom_type_at_save` for this domain. Did not query user workout content, alter data, run transactions or deploy.
- Existing SQL test precedent: `supabase/tests/database/tnyx_509_routine_composition.test.sql` + `tnyx_509_routine_composition_concurrency.sh`, using disposable local Supabase sessions and owner A/B fixtures.

## 3. Clarification / Gate

| Decision | Status | Why |
| --- | --- | --- |
| Name edits in shared Edit Routine input, not rename popup | **Approved product behavior** | Owner correction; keep Create/Edit single visual composer. |
| Never perform separate client `rename()` then `save()` | **Locked security invariant** | Partial commit and inconsistent retries possible. |
| Legacy Data API UPDATE(name) retention versus sunset | **Needs rollout decision** | Old clients can still overwrite names without CAS until blocked; only optimistic detection of writes *before* upgraded RPC is possible. |
| Treat existing composition revision/token as one Routine-wide aggregate mutation marker | **Proposed, needs semantic-shape owner gate** | Would avoid a new column, but changes an existing column's meaning and requires legacy write compatibility. |
| Versioned RPC evolution without ambiguous PostgREST overload | **Implementation design gate** | Preserve old 4-arg contract while introducing name-aware one without duplicated validation drift. |

## 4. Architecture Design

**Preferred, not yet approved:** Owner-authorized server-side mutation under one parent row lock. Request distinguishes no-change from empty composition: optional new Name is `null` only when unchanged, optional Exercise array is `null` only when unchanged; an empty array is a **real** empty composition. At least one field must request a change. Freeze Routine identity, Program ownership/owner identity from verified session, expected revision, expected original Name (or an equivalent CAS), mutation UUID, and requested contents *before* transport. New `p_name` cannot be a separate client rename. Server must preserve all existing Custom Exercise/Set-type/legacy protections and identical replay semantics.

**Mandatory server decision order (Codex P1):** authenticate/resolve owner + Program/Routine identity, acquire parent-row lock, validate request shape and build canonical normalized requested contents **without child writes**, then check **same mutation UUID first** against the complete persisted outcome for every requested field (including Name and composition) and frozen identity/scope. Identical replay returns the confirmed authoritative result **even though expected Name/revision are now stale**; reused UUID with different request/scope must fail closed. Only for a **new** mutation UUID check expected revision and expected baseline Name/CAS before any mutation, followed by remaining owner-safe Custom/legacy validations and one atomic write. The existing four-arg RPC already checks the matching mutation token before its expected-revision conflict. No state-only equality shortcut may be called "exact request replay" if omitted fields or baseline metadata make two different requests indistinguishable: prove a verifiable complete-request fingerprint or equivalent durable comparison, or leave that implementation blocked pending explicit storage-contract approval.

**Critical legacy compatibility:** To reuse existing revision/token columns for the *whole* Routine, old direct `UPDATE(name)` would need a narrowly owned revision-increment + mutation-token invalidation trigger when Name **actually** changes; any new combined RPC must increment revision exactly once and not accidentally double-bump. The old 4-arg RPC must stay callable by older clients, with exactly preserved per-Set validator behavior. This is an explicit **proposed semantic migration** requiring approval and tests, not a change made by this PR. Until a sunset of direct UPDATE(name), an old client may **later** overwrite a new client's committed Name; do not claim perfect cross-version lost-update prevention. New clients detect stale inputs when the rename ran **before** their locked operation; an intervening old-client update after commit is an observable new revision, not a retroactive rollback.

**Non-duplicated implementation direction:** Maintain one canonical server-side validation/execution path for Exercise/Set saves. A separate five-argument RPC copy of the 500+ line composition function is **rejected** (security drift). Overloaded defaulted RPCs without verified PostgREST dispatch are **rejected**. Design a versioned name-aware RPC + safe legacy wrapper/delegation only after combined replay / transaction / grants tests prove no extra EXECUTE surface or compatibility break.

**Rollback-safe compatibility gate (Codex P1; required BEFORE SQL design):** Phase A, measure supported minimum app/API versions, name-write routes, archived Custom clients and target adoption window; establish testable forward/rollback invariants. Phase B, deploy *additively* a versioned name-aware RPC and any separately approved aggregate-revision guard **database first**, while the old four-argument composition RPC and authenticated direct `UPDATE(name)` remain callable; test old vs new clients, row-lock ordering, trigger scope, no double revision bump, identical replay and previous rich Set profiles. Do **not** revoke legacy grants or switch Flutter before verified rollout. Phase C, release the new Flutter editor only after target DB version, grants, schema-cache/API availability, and backwards compatibility are independently verified; ship monitoring/feature gate and app-side rollback to old flow, without adding a fake two-write fallback. Phase D, sunset direct Rename/update grants **only** after explicit supported-client adoption or enforced minimum-version policy and validated migration; otherwise keep the residual old-client Name overwrite risk visible. **Rollback rule:** once new app clients depend on the new RPC/revision semantics, do not roll back DB functions/trigger/grants to an incompatible old version; prefer a compatible forward fix, or first disable the new app capability, drain/verify in-flight and unknown-outcome writes, and prove compatibility before rollback. Maintain the old client path for app rollback throughout overlap. Production migrations/deployments are separately gated; no target dates or minimum versions are assumed.

**Idempotency/recovery:** For a matching mutation UUID, verify full original **request identity/field mask/normalized payload** and persisted Name/Exercise+Set outcome **before** stale CAS; refuse divergent same-token payload. A server revision and final state alone may be insufficient to distinguish two different requests: choose/prove storage or canonical fingerprint representation before claiming complete idempotency. For a new UUID, apply expected revision/Name CAS first, then mutate atomically. Outcome-unknown client verification must read both the owner Name and revision-validated ordered Set snapshot, observing the mutation marker. If later writers supersede the marker, do not claim successful reconciliation; do not silently retry under a fresh UUID.

**Data boundaries:** Supabase/Postgres owns atomic security and transaction. Workout feature repositories/controllers own frozen command, State (loading/ready/saving/conflict/unknown), and explicit refresh. Shared `RoutineComposerScreen` preserves physical design. No service-role key or direct Set DML exposed to mobile.

## 5. Implementation Sequence — not yet started

- [x] Fresh GitHub/Linear/canonical doc/current source read, current-head and concurrent-owner check.
- [x] Live read-only migration/columns/functions/grants/trigger read on correct Supabase project.
- [x] Propose small compatible server contract and capture rejected alternatives.
- [ ] Independent re-review of two Codex P1 contract findings, including replay-before-CAS ordering and required full-request identity proof.
- [ ] Decide additive DB-first / compatible app-rollback / grant-sunset rollout and material column-semantics owner approval **before** drafting SQL.
- [ ] New **database-only** reviewed slice: RFC into SQL migration and RLS/concurrency tests in disposable local Supabase, preserve 4-arg client compatibility and document backward-compatible forward-fix behavior.
- [ ] Verify hosted migration replay/grants/advisors **only after explicit deployment gate**.
- [ ] New **Flutter-only** reviewed slice: Name field in existing shared composer with combined repository/controller command and proper uncertain read; no partial writes.
- [ ] Separate 3-dot Edit Routine routing and Delete #526 lifecycle, after name editor is real.
- [ ] Exact-head CI, Codex, light/dark/compact, auth A/B and owner device QA before merge.

## 6. Quality Review

**Read-only security audit:** Verified hosted metadata only; no data rows, DDL or DML. Codex initial review `7ed01fdf` found two legitimate P1 contract omissions: retry ordering and rollback sequence; updated design requires both. No CI or database test run on this docs-only branch. Updated exact-head independent re-review pending.

## 7. Final Handoff

**Changed files:** This task brief; linked canonical screen spec gate; task index.
**Actual behavior:** Unchanged.
**Known limitations:** Legacy direct Rename bypasses composition revision; solving it is a separate reviewed implementation/rollout decision. Local Windows HEAD still needs fetch after recent merges.
**Final status:** **REVIEW** — contract proposed, not approved or deployed.

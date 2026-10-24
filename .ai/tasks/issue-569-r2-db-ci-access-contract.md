# GitHub #569 R2: Database CI Access Contract Preparation

**Status:** In progress — PR #673 review remediation; production Move remains OFF.
**Owner approval:** The 2026-10-24 R2 request authorizes this bounded CI preparation. The 2026-10-23 Option A decision still withholds hosted three-RPC access pending a separate explicit all-signed-in exposure decision.

## Active Handoff

**Planning owner:** GitHub #569 / Linear TNYX-81
**Implementation owner:** `im-tnyx` (this R2 CI slice only)
**Review owner:** `im-tio` requested changes on PR #673; independent human security review remains pending.
**Implementation ownership state:** Active
**Repository state last verified:** Clean `main@86f0afa8711dec28a57e513f33031e779516fa10`; GitHub `main` matched through connected GitHub read.
**Branch:** `tnyx/569-r2-db-ci-access-contract`
**Observed uncommitted/dirty files:** None before this slice.
**Current implementation state:** Source head `bc68089917ff15806f1a02153bac0015b2db6e13` shares the three-RPC ACL cleanup between races and the denied/granted success/failure regression; disposable DB CI passed. This handoff is a later docs-only PR amendment, so its final-head receipts must be checked separately.
**Validation remaining:** Verify checks on the final PR head, request Codex and `im-tio` re-review, close verified threads, and obtain separate independent human security sign-off before merge.
**Next exact action:** Verify final-head CI and review results; keep hosted access and the production flag OFF.

## 1. Discovery

### User outcome and scope

Prepare #569 database CI for a future three-RPC authenticated-only production grant without granting hosted access now. Change only `.github/workflows/supabase-db-ci.yml`, #569 SQL fixtures, and this brief/task index. Keep one centralized current dormant-ACL assertion; make race fixtures restore the ACL they found at start.

### Non-goals

No migration, hosted SQL write, production Flutter flag, UI change, #567 Delete Program, merge or deployment. This slice does not authorize all signed-in RPC exposure.

## 2. Codebase Exploration

- GitHub #569 is OPEN; TNYX-81 and TNYX-267 are Backlog. #567 is a separate open destructive Program Delete lifecycle.
- Hosted project `oykupyiitspujzpwwvuj` currently has 69 applied migrations and all three `postgres`-owned `SECURITY DEFINER` Move RPCs have empty `search_path` and client EXECUTE denied (read-only catalog check, 2026-10-24).
- `20261021130000` enforces permanent `auth.users.is_anonymous IS FALSE` admission for Move/Create+Move; `20261024090000` adds exact provenance and protected full Undo. All three remain dormant.
- Four SQL matrices assert pre-grant `authenticated=false`; three multi-session workflow blocks unconditionally revoke temporary grants after races. A forward grant would make these fail or erase the migrated ACL in disposable CI.

## 3. Clarification and decision

Keep Option A isolated QA and the release flag OFF. This PR only removes the CI coupling; a later grant PR must explicitly switch the central ACL contract to `authenticated=true` for exactly three signatures after a separate owner exposure decision.

## 4. Architecture design

Use one durable ACL contract SQL test for the current migration state. Operation matrices test ownership, CAS, retries and direct-write denial regardless of durable authenticated EXECUTE. Multi-session race setup records initial access, grants temporarily, then restores the same initial access under a disposable-DB guard.

### Proposed next migration and rollback (not included in this slice)

After an explicit owner decision to expose these RPCs to **all permanent signed-in accounts**, author one new imperative migration from the current 69/69 baseline. It must target only these exact identities:

```sql
public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)
public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)
public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)
```

Preflight the three `postgres` owners, `SECURITY DEFINER`, empty `search_path`, reviewed function bodies, trusted permanent-account check, and Program/Routine RLS/direct-write denial. In one migration transaction, `REVOKE ALL ON FUNCTION` for each signature from `PUBLIC, anon, authenticated, service_role`, then `GRANT EXECUTE ON FUNCTION` for each signature only to `authenticated`. Change the centralized CI ACL contract from denied to exactly these three authenticated grants and retain negative checks for `PUBLIC`/`anon`/`service_role` and direct `UPDATE(program_id)`/Program `DELETE`. Do not add table privileges, change the function bodies, or activate Flutter in that PR.

The separate rollback migration must `REVOKE EXECUTE` on those three exact identities from `authenticated` (and verify `PUBLIC`/`anon`/`service_role` remain denied). Recheck ACLs and a permanent-account test call denied with SQLSTATE `42501`; retain functions, provenance, history, and committed workout data. Revocation blocks new calls, not transactions already executing. Reconcile any UNKNOWN client result by owner-scoped mutation receipt before retrying or claiming Undo. Never reverse the applied 69 migrations for access rollback.

Release sequence: CI compatibility PR -> owner exposure decision -> single grant/rollback security PR and independent human review with exact-head disposable DB CI -> explicit hosted apply authorization and read-only ACL/advisor verification -> separate Flutter production activation build -> Android and iOS real-write, timeout/UNKNOWN, race, Undo and rollback acceptance -> release decision. #567 user-initiated Delete Program remains separately gated.

## 5. Implementation plan

- [x] Centralize current dormant three-RPC ACL assertions.
- [x] Remove the durable-dormant premise from operation matrices while preserving `anon`/`service_role`/direct-write denial.
- [x] Restore initial authenticated ACL in race cleanup and verify exact post-test state. The P2 correction shares this cleanup with a disposable denied/granted success/failure regression.
- [x] Run focused validation and disposable DB CI on source head `bc68089917ff15806f1a02153bac0015b2db6e13`.
- [x] P2: run denied/granted ACL restore regression and failure cleanup for all three signatures in disposable CI (step 49).
- [x] P3: record the source-head CI, review findings and pending final-head/review gates below.
- [ ] Verify checks on the final docs-amended PR head and obtain fresh reviews.

## 6. Quality review

**Validation run:** Source head `bc68089917ff15806f1a02153bac0015b2db6e13`: [Supabase Database CI 40091047752](https://github.com/im-tnyx/tio-world/actions/runs/40091047752) SUCCESS, including migration replay, existing Move/Create+Move/Undo matrices and races, step 49 denied/granted ACL success/failure cleanup for all three exact signatures, and step 50 dormant three-RPC reassertion; [Docs Hygiene 40091047728](https://github.com/im-tnyx/tio-world/actions/runs/40091047728) SUCCESS. Local PyYAML workflow parse and `git diff --check` passed; local Bash syntax execution was unavailable because the Windows sandbox denied MSYS named-object creation (`0xC0000022`). Required Commit attribution guard and final docs-amended-head checks remain to verify. Prior head `57b71fb3` passed DB CI 40089433584 and Docs Hygiene 40089433574 but covered only the denied baseline.
**Review provenance:** `im-tio` GitHub review [CHANGES_REQUESTED](https://github.com/im-tnyx/tio-world/pull/673#pullrequestreview-5638092222) at prior head; P2 and P3 inline threads await evidence replies and re-review. This connected-account review does not establish independent human security sign-off.

| Finding | Severity | Status | Required resolution |
|---|---|---|---|
| P2 ACL granted-baseline cleanup untested | P2 | Fixed in `bc680899`; review pending | Step 49 passed denied/granted success/failure cleanup for all three signatures; step 50 reasserted migrated ACL. |
| P3 handoff stale | P3 | Corrected in this amendment; review pending | Source-head CI, implementation and next merge gates are recorded here; final-head receipts belong in PR replies after this amendment is pushed. |

## 7. Handoff

**Status:** REVIEW. Final-head checks, Codex re-review, distinct-account re-review, resolved threads and independent human security review remain before merge. Future grant migration and all-signed-in exposure decision are separate R2 gates.

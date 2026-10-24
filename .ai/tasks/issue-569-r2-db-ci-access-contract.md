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
**Current implementation state:** PR #673 head `57b71fb32caf8e22e8006495b0a686b6f250c9bc` passed denied-baseline CI; P2 granted-baseline/failure cleanup coverage and P3 handoff freshness remain open.
**Validation remaining:** New exact-head disposable DB CI, Codex re-review, `im-tio` re-review and separate independent human security sign-off.
**Next exact action:** Exercise the shared ACL restore path for all three signatures from both denied and granted baselines, including simulated fixture failure, then refresh exact-head evidence.

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
- [ ] Run focused validation and exact-head disposable DB CI if available.
- [ ] P2: run denied/granted ACL restore regression and failure cleanup for all three signatures in disposable CI.
- [ ] P3: record exact new-head CI, review findings and handoff status.

## 6. Quality review

**Validation run:** Prior head `57b71fb32caf8e22e8006495b0a686b6f250c9bc` passed Supabase Database CI [40089433584](https://github.com/im-tnyx/tio-world/actions/runs/40089433584), Docs Hygiene [40089433574](https://github.com/im-tnyx/tio-world/actions/runs/40089433574), and required Commit attribution guard. These runs covered denied-baseline restoration only. New-head checks are pending.
**Review provenance:** `im-tio` GitHub review [CHANGES_REQUESTED](https://github.com/im-tnyx/tio-world/pull/673#pullrequestreview-5638092222) at prior head; P2 and P3 inline threads open. This connected-account review does not establish independent human security sign-off.

| Finding | Severity | Status | Required resolution |
|---|---|---|---|
| P2 ACL granted-baseline cleanup untested | P2 | Open | Exercise success and failure cleanup under denied and granted starting ACL for all three signatures in disposable CI. |
| P3 handoff stale | P3 | Open | Record implementation, exact-head validation, review state and next merge gate. |

## 7. Handoff

**Status:** REVIEW until exact-head CI and independent security review are complete. Future grant migration and exposure decision are separate R2 gates.

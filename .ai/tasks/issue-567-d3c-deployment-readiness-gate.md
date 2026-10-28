# GitHub #567 D3C — Program Delete Deployment Readiness & Owner Approval Gate

**Status:** Needs decision (`AWAITING OWNER APPROVAL`)
**Primary owner:** Antigravity (Architecture & Security Lead)
**Affected platforms:** Supabase Database & Flutter `apps/features/workout`

## Owner Approval and Scope Boundary

**Trigger:** Supabase RPC deployment / permission grants & future UI activation
**Approval status:** `AWAITING OWNER APPROVAL`
**Approval evidence:** Pending owner decision on this readiness brief.
**Approved product/UI/data-shape boundaries:**
- Read-only audit and structured multi-stage deployment plan.
- Definition of sequential release gates (Gate A, Gate B, Gate C, Gate D).
- Formal specification of forward grant migration and validation contracts.
**Explicit non-changes:**
- ZERO remote database mutations, migrations, grants, or schema updates during D3C.
- ZERO UI activation or modifications to `programs_surface.dart`.
- Program Delete flow remains completely dormant and uncallable in production.

## Active Handoff

**Planning owner:** Antigravity
**Implementation owner:** Antigravity
**Review owner:** Architecture & Security Lead
**Implementation ownership state:** Paused (Awaiting Owner Approval)
**Ownership transition:** Not applicable
**Repository state last verified:** `G:/projects/Tio-World` at branch `tnyx/issue-567-d3c-deployment-readiness-gate`; working tree was clean at audit start
**Branch:** `tnyx/issue-567-d3c-deployment-readiness-gate`
**Base / reconciliation SHA:** base `origin/main`=`ca3817af8b05c707d026a30d0c0f3c560a009185`; correction commit=`1a24109ce160fd375e8fc9b8818838fc8fe4c970`; reconciliation merge=`58f9434d1931b95b3e47d17e6f3a59c9e84b1c17`
**Branch state:** Reconciled with current `origin/main` through a non-rewriting merge; no rebase, force-push, or history rewrite was performed. Push is pending.
**PR / tracker:** GitHub #711 `OPEN` with `CHANGES_REQUESTED`; Linear TNYX-81 / TNYX-267 Backlog
**Current implementation state:**
- D1 (RPC logic & DB CI tests) committed on mainline.
- D2A (Repository adapter & DTO) merged.
- D2B (Controller & state machine) merged.
- D3 (Presentation confirmation flow & 17 unit/widget tests) merged in PR #708.
- Repository source contains Migration #71 (`20261025100000_delete_user_workout_program_preserving_routines.sql`) and Migration #72 (`20261028110000_grant_authenticated_program_delete_rpc.sql`), and local/CI test definitions exercise their replay/ACL behavior. Source presence or replay tests do not prove hosted deployment.
- Current canonical repository evidence in `docs/screens/programs.md` states that Migration #71 is not applied on hosted Supabase, the hosted ledger was 70 migrations through `20261024120000`, client `EXECUTE` was not granted, and no Delete UI exists.
- **Gate A hosted status:** `NOT VERIFIED / NOT COMPLETE` in this audit. No hosted read-only receipt or live metadata was accessed, and the repository evidence contradicts the brief's previous “deployed & verified” claim.
- **Gate B hosted status:** `NOT VERIFIED / NOT COMPLETE` in this audit. The checked-in grant migration is source evidence only; no authoritative hosted grant receipt was available, and canonical repository evidence says client `EXECUTE` is not granted.
- Gate C hosted disposable-account QA has not been run and remains unauthorized pending explicit Owner approval and a controlled test-account plan.
- Local Docker engine and hosted Supabase were not accessed or mutated. Production UI remains disconnected and dormant.
**Relevant execution surface:** `supabase/migrations/`, `apps/features/workout`
**Validation completed at SHA:** Read-only branch/ref audit, source migration inspection, canonical Programs-doc comparison, current GitHub PR metadata/review/check inspection, and `git diff --check` after the local correction. No hosted Supabase or local database execution was performed.
**Validation remaining:** Authoritative hosted status/receipt for Gates A/B and the Gate C disposable-account verification remain unavailable and unauthorized.
**Current blocker:** Requires explicit Owner Approval before any hosted migration, permission grant, hosted QA, or UI activation; the updated PR requires independent review before merge consideration.
**Open review finding IDs:** GitHub PR #711 review thread `4398976641` remains `UNRESOLVED` with `CHANGES_REQUESTED` for the Gate A/B contradiction. This local correction is not remotely resolved or reviewed.
**Next exact action:** Submit this corrected decision brief to the Owner and await an explicit approval decision plus authoritative hosted deployment/read-only evidence. Until then, no migration, grant, hosted QA, production UI activation, or merge is permitted.

---

## Deployment Architecture & Gate Sequence

### Gate A — Migration #71 RPC Definition Application
- **Current status:** `NOT VERIFIED / NOT COMPLETE` for hosted readiness; source migration exists, but repository evidence does not establish that it was applied remotely.
- **Scope:** Push existing migration `20261025100000_delete_user_workout_program_preserving_routines.sql` to hosted Supabase.
- **Security Posture Upon Deployment:**
  - `SECURITY DEFINER` with fixed `set search_path = ''`.
  - Registered account guard: `identity.is_anonymous is false` (blocks anonymous JWTs).
  - UUID-ordered locking on `public.users` and `public.user_workout_programs` (deadlock-free).
  - Dynamic FK cascade protection (`pg_constraint` assertion).
  - Strict membership comparison: caller expected UUID array matches actual UUID array.
  - Fail-closed privilege: migration explicitly executes `revoke all on function public.delete_user_workout_program_preserving_routines(...) from public, anon, authenticated, service_role;`.
- **Verification Post-Deploy:**
  - Verify function exists in `information_schema.routines`.
  - Verify `has_function_privilege` returns `false` for `anon`, `authenticated`, `public`, and `service_role`.
  - Verify direct table `DELETE` on `user_workout_programs` remains denied via RLS.
- **Rollback / Recovery Plan:**
  - Execute `drop function if exists public.delete_user_workout_program_preserving_routines(uuid, uuid[], uuid);`.
  - Zero table/column schema changes exist in Migration #71, so rollback carries zero data loss risk.

### Gate B — Authenticated EXECUTE Grant Migration
- **Current status:** `NOT VERIFIED / NOT COMPLETE` for hosted readiness; source grant migration exists, but repository evidence does not establish that the hosted grant was applied.
- **Scope:** Create and apply dedicated forward migration (e.g. `20261028110000_grant_authenticated_program_delete_rpc.sql`).
- **Exact DDL Content:**
  ```sql
  grant execute on function public.delete_user_workout_program_preserving_routines(
    uuid, uuid[], uuid
  ) to authenticated;
  ```
- **Security Guardrails:**
  - Explicitly restrict grant to `authenticated` role only.
  - `anon` and `public` remain strictly revoked (`REVOKE ALL`).
  - Requires explicit owner sign-off prior to application.

### Gate C — Hosted Disposable-Account Verification
- **Scope:** Automated / scripted verification against hosted Supabase using disposable test accounts.
- **Execution Matrix:**
  1. **Anonymous / Unauthenticated Denial:** Attempt RPC call with anonymous token or invalid JWT -> Must fail with `program_delete_not_authenticated` or `program_delete_registered_account_required`.
  2. **Non-Owner Access Denial:** Attempt to delete User B's program using User A's token -> Must fail with `program_delete_not_found` (P0002).
  3. **Protected Default Program Guard:** Attempt to delete canonical default program (`is_default: true`) -> Must fail with `program_delete_default_forbidden` (P0001).
  4. **Atomic Routine Reparenting:** Delete non-default program containing 3 routines -> Must reparent all 3 routines to canonical `My Program` atomically, increment revisions, and delete source program.
  5. **Zero-Routine Clean Container:** Delete empty program -> Must cleanly delete program without creating or modifying `My Program`.
  6. **Network Retry Idempotency:** Re-executing delete with same or stale parameters after source deletion -> Must return `not_found` / fail-closed, never corrupt or recreate data.
  7. **Cleanup:** Delete disposable test accounts immediately following test suite execution.

### Gate D — Production UI Exposure (D4)
- **Scope:** Enable Delete Program action in `apps/features/workout/lib/src/presentation/library/programs/programs_surface.dart`.
- **Strict Preconditions:**
  - Gates A, B, and C must be 100% verified and documented with passing evidence.
  - Zero regressions in existing Routine/Program UI.
  - No visual geometry or styling diff outside governed `TioCard` / `TioButton` design tokens.

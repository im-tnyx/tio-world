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
**Repository state last verified:** `G:/projects/Tio-World` at branch `main`
**Branch:** `main`
**HEAD SHA:** `780fb56d1fd47d55666ed5d0a6d881992f314ff2` (clean tree, in exact sync with `origin/main`)
**PR / tracker:** GitHub #567 OPEN (PR #708 merged); Linear TNYX-81 / TNYX-267 Backlog
**Current implementation state:**
- D1 (RPC logic & DB CI tests) committed on mainline.
- D2A (Repository adapter & DTO) merged.
- D2B (Controller & state machine) merged.
- D3 (Presentation confirmation flow & 17 unit/widget tests) merged in PR #708.
- Hosted Supabase (`oykupyiitspujzpwwvuj`): Gate A & Gate B COMPLETED.
  - Migration #71 (`20261025100000_delete_user_workout_program_preserving_routines.sql`) deployed & verified.
  - Migration #72 (`20261028110000_grant_authenticated_program_delete_rpc.sql`) deployed & verified.
  - 72/72 remote ledger count.
  - Function `public.delete_user_workout_program_preserving_routines(uuid, uuid[], uuid)` exists as `SECURITY DEFINER` with empty `search_path`.
  - EXECUTE privileges: `can_execute` is `true` for `authenticated`; strictly `false` for `anon`, `service_role`, `public`.
  - Direct table `DELETE`: `can_delete_programs` and `can_delete_routines` are `false` for `anon`, `authenticated`, `public`. Zero DELETE policies in RLS.
  - Gate C QA Audit: Phase 1 completed. Test matrix mapped across all 13 criteria.
  - Local Docker engine: Unavailable on this workstation.
  - GitHub Actions DB CI: 100% green on Run `40162185101` (SQL suite + 3 concurrency race harnesses passed).
  - Awaiting Owner instruction for Phase 2 QA execution (disposable identity hosted smoke test authorization).
  - Production UI remains disconnected and dormant.
**Relevant execution surface:** `supabase/migrations/`, `apps/features/workout`
**Validation completed at SHA:**
- Flutter delete-suite: 39/39 tests PASS (`program_delete_flow_test.dart`, `program_delete_controller_test.dart`, `supabase_workout_repository_test.dart`).
- `flutter analyze --no-pub`: 0 issues across all packages.
- Supabase local/CI: 14 SQL assertions + 3 concurrency race matrices passing in CI (`supabase-db-ci.yml`).
**Validation remaining:** Remote hosted verification (Gate C) after Gates A & B approval.
**Current blocker:** Requires explicit Owner Approval before hosted migration or permission grants.
**Open review finding IDs:** None
**Next exact action:** Submit decision brief to Owner and await authorization.

---

## Deployment Architecture & Gate Sequence

### Gate A — Migration #71 RPC Definition Application
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

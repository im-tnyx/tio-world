# #569 M3C — Flutter protected atomic Create Program & Move adapter

**Status:** In progress — audit-first, dormant data/domain slice.
**Primary owner:** Workout feature domain/data.
**Affected platforms:** Flutter phone repository capability only; no active UI entrypoint.

## Owner Approval and Scope Boundary
**Trigger:** None — bounded implementation subtask of the previously owner-approved GitHub #569 Move Routine, including the `+ New Program → canonical editable name → Create & Move` flow. User requested "Go start ... audit kare pahle" on 2026-10-18.
**Approval status:** Owner-approved parent behavior; this is implementation of its existing protected adapter dependency.
**Approved boundaries:** Implement **one** Flutter client RPC adapter for `create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)` with frozen identity/revision, owner+login-cycle checks, one-use attempt, and conservative timeout/unknown handling. Reuse existing M3A `RoutineMoveAttemptGate` for existing and new Program Move.
**Explicit non-changes:** No apps/app routing or Routine 3-dot `onMove` wiring, production UI layout, #568 My Program identity, new database/schema/migration, hosted RPC deployment, EXECUTE grant, privileged key, two-step create+move, merge or release.

## Active Handoff
**Planning owner:** GitHub #569; Linear TNYX-81/TNYX-267 (broad Backlog with parent blockers).
**Implementation owner:** `tnyx/issue-569-m3c-atomic-create-move-flutter-adapter` exclusively.
**Review owner:** GitHub CI and independent inline reviewer after PR.
**Implementation ownership state:** Active.
**Repository baseline verified:** Protected `main@55ef926e9ed1be1300061f065b8f3458019410d7`, PR #600 merged, 0 open PRs at start; `AGENTS.md` and `apps/features/AGENTS.md` read, ADR-0015 accepted.
**Environment:** GitHub connector remote branch only; Windows checkout `G:\projects\Tio-World` and local `git status`/Flutter execution cannot be inspected or claimed.

## 1. Discovery
- Existing `RoutineMoveFlow` in merged #600 calls optional `RoutineCreateMoveCallback` only after explicit name editor and confirmation. It does **not** supply a production callback.
- Existing `SupabaseRoutineMoveRepository` M3A owns owner-scoped Routine header inspect, one-use tokens, shared in-process Move attempt gate, no retry and UNKNOWN reconciliation.
- Current hosted Supabase read-only audit: 64 applied migrations, atomic Create+Move RPC **absent**, existing Move client EXECUTE **false**, direct Routine program_id and name UPDATE **false**.
- Root `AGENTS.md`, ADR-0015, Workout ownership, GitHub #569 and Linear TNYX-81/TNYX-267 constrain the slice. Existing source is actual behavior; task handoffs from merged #599/#600 contain stale Open/Ready claims and are historical rather than runtime truth.

## 2. Codebase Exploration
Owned paths: `apps/features/workout/lib/src/domain/repositories/routine_move_repository.dart`, `apps/features/workout/lib/src/data/repositories/supabase_routine_move_repository.dart`, focused repository tests, this brief and task index. Current gateway uses `.retry(enabled: false)` for RPCs and stable owner/login-cycle header reads. Existing `RoutineMoveAttemptGate` prevents independent Move duplication; a separate per-route gate would be a concurrency regression.
Supabase source contract is the single dormant migration `20261018100000_atomic_create_program_and_move_routine.sql` on main, owner/CAS-guarded, committed in one transaction; its server-side SQLSTATE exceptions are prefixed `routine_create_move_*`.

## 3. Clarification
Treat all post-dispatch ambiguous responses as UNKNOWN even if an owner-scoped later read sees an apparent destination: only an exact server RPC response is success. Never create a second Program or retry with a new ID/token on timeout. Client capabilities remain dormant when no app provider injects them.

## 4. Architecture Design
Reuse `RoutineMoveTarget` (owner, login cycle, immutable source revision) and existing Move attempt gate. Add an optional domain capability for one atomic Create+Move call, wired to the existing Supabase repository implementation. A gateway maps the six named parameters in one `client.rpc` request. Distinguish known permission/invalid/collision/revision denials from unknown network/timeouts; keep conservative post-dispatch UNKNOWN on uncertain outcomes. No new ProgramRepository.create, direct table UPDATE, or app-shell dependency.
Rejected alternative: separate `ProgramRepository.create` followed by Move, because transactionality/orphan safety is violated. Rejected alternate gate: a new gate instance allows concurrent existing/new Move against the same Routine.

## 5. Implementation Plan
- [ ] Add the optional owner-scoped atomic repository contract and single RPC gateway.
- [ ] Reuse process-shared M3A guard for existing/new Move; one-use and uncertain outcomes across both paths.
- [ ] SDK request + auth-switch, duplicate, timeout/unknown, definitive denied/collision tests; maintain existing Move tests.
- [ ] Exact source HEAD GitHub Flutter CI, independent security review, resolve findings.
- [ ] Explicit future app-shell, hosted migration/grant and owner merge/release gates separately approved and verified.

## 6. Quality Review
GitHub root + feature AGENTS, ADR-0015, canonical Programs/Routine docs and current source audited. No local Flutter/device execution; only future exact-head GitHub CI may establish tested implementation.

## 7. Final Handoff
**State:** implementation starting in one new bounded branch after current-source audit; no hosted deployment or user-facing activation.

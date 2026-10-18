# #569 M3C — Flutter protected atomic Create Program & Move adapter

**Status:** In Review — [PR #601](https://github.com/im-tnyx/tio-world/pull/601) Open / **Ready for Review** (not Draft, unmerged). Five Codex P2 findings tracked: first four fixed, their threads resolved; latest [P2 `PGRST300` #4306602635](https://github.com/im-tnyx/tio-world/pull/601#discussion_r4306602635) fixed in source `c414bd97`, regression tests `807010d4` (new exact-head CI pending). The prior [Flutter CI #39113781233](https://github.com/im-tnyx/tio-world/actions/runs/39113781233) at `3b1fa96b` **7/7 SUCCESS**; the subsequent implementation and handoff commits require separate exact-head checks. No merge or activation.
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
**Review owner:** Codex code review on `3b1fa96b` completed after a reset and identified fifth P2 (`PGRST300` JWT-secret configuration rejection previously misclassified as uncertain); current source/test fix committed, CI and thread disposition pending. Four earlier P2s remain resolved. [Previous quota-limit failure](https://github.com/im-tnyx/tio-world/pull/601#issuecomment-6247959316) is historical, not current code-review status. No independent GitHub `APPROVED` or completed Codex security review verified.
**Implementation ownership state:** Active on one dedicated source branch; no parallel implementation.
**Repository baseline verified:** Protected `main@55ef926e9ed1be1300061f065b8f3458019410d7`, PR #600 merged, 0 open PRs at start; `AGENTS.md` and `apps/features/AGENTS.md` read, ADR-0015 accepted.
**PR:** [#601](https://github.com/im-tnyx/tio-world/pull/601) Ready for Review. Original `2aa33cb` [CI #39106667479](https://github.com/im-tnyx/tio-world/actions/runs/39106667479) **7/7 PASS**; fixed two P2 via `0fe24891` + tests `5a2bdf7d`, [CI #39112881033](https://github.com/im-tnyx/tio-world/actions/runs/39112881033) **7/7 PASS**; latest `PGRST303` source fix `58c8aed9`, regression `f4ded10c` and task governance fixes `3cfcee0d`/`ba3aae37` are all included in `ba3aae37`: [CI #39113377190](https://github.com/im-tnyx/tio-world/actions/runs/39113377190) 7/7 SUCCESS. The next docs-only `3b1fa96b` [CI #39113781233](https://github.com/im-tnyx/tio-world/actions/runs/39113781233) was also 7/7 PASS. Codex code re-review on that SHA completed with new P2 `PGRST300`, fixed in `c414bd97` + `807010d4` tests; exact subsequent HEAD CI pending, then owner merge gate.
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
- [x] Add `RoutineCreateMoveRepository` optional domain capability and one `SupabaseRoutineMoveGateway.createAndMove()` protected RPC (no table writes).
- [x] Reuse process-shared M3A gate for existing/new Move; one-use prepared target, in-flight and uncertain revision share one identity.
- [x] Add SDK JSON/payload, owner/session switch, cross-route in-flight, invalid, timeout/unknown, definite denied/collision and pre-dispatch PostgREST auth/routing tests. Existing M3A tests retained; CI #39112881033 validated source+tests through `5a2bdf7d` 7/7.
- [x] Address Codex P2 #4306389762 (stale login-cycle on definitive error) and #4306389767 (pre-execution `PGRST203` gate poison) in `0fe24891`/`5a2bdf7d`; exact-head CI PASS 7/7. Replies posted, original threads awaiting re-review/disposition.
- [x] Address Codex P2 #4306413124 (`PGRST303` JWT claims failure must be definite pre-execution unauthorized) in `58c8aed9`/`f4ded10c`. Mapping matches Supabase official PostgREST errors; CI pending on this later HEAD.
- [x] Address Codex P2 #4306413128 (active handoff falsely says Draft and earlier CI incomplete) with this brief and task index. Superseded historical gates explicitly distinguished from latest SHA.
- [x] Historical exact-head Flutter CI #39113377190 (`ba3aae37`) and #39113781233 (`3b1fa96b`) **7/7 PASS** (Workout, nutrition, core/wear, analyzer, aggregate, 2 attribution); four earlier Codex P2 threads **resolved**.
- [x] Current Codex [P2 #4306602635](https://github.com/im-tnyx/tio-world/pull/601#discussion_r4306602635): PostgREST `PGRST300` means missing active JWT secret (HTTP 500 but pre-execution) per Supabase official error table. Treat it as definitive `unavailable` even with status 500; regression covers atomic rejection, zero unknown reconciliation, same-gate fresh existing Move. Fix `c414bd97`, test `807010d4`.
- [x] Nonblocking prior [P3 #4306568293](https://github.com/im-tnyx/tio-world/pull/601#discussion_r4306568293): task brief/index now distinguish exact completed `3b1fa96b` 7/7 and four resolved P2 threads from **new source/docs HEAD** with CI pending.
- [ ] Fresh exact-source/docs HEAD Flutter CI; fifth P2 inline reply/resolution after verifying; Codex code/security re-review, independent `APPROVED` or recorded policy disposition, separate owner `Go merge`.
- [ ] Explicit future app-shell, hosted migration/grant and owner merge/release gates separately approved and verified.

## 6. Quality Review
GitHub root + feature AGENTS, ADR-0015, canonical Programs/Routine docs and current source audited. CI #39106667479, #39112881033, #39113377190 and #39113781233 all **7/7 PASS at their respective exact HEADs**. Codex code re-review on `3b1fa96b` completed with fifth P2; source `c414bd97` and test `807010d4` corrections are still awaiting new CI. Codex security review has not been verified complete; no APPROVED review, local Flutter/device execution, hosted grant/deploy or live activation claimed. No local Flutter/device execution. Hosted Supabase still NOT activated.

## 7. Final Handoff
**State:** [PR #601](https://github.com/im-tnyx/tio-world/pull/601) Ready for Review and unmerged; four earlier Codex P2s resolved, fifth P2 `PGRST300` fix and tests committed, new exact-head CI/re-review pending. Previous exact-head CI #39113781233 7/7 PASS. The nonblocking P3 handoff-state drift is reconciled in this brief/index; thread disposition pending. No independent APPROVED or security-review completion claimed. No app-shell Move callback, migration, hosted grant, deployment or user-facing activation. Only close threads once CI and source evidence is verified.

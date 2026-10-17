# #569 M3B1 — Owner Program Move destination controller

**Status:** In progress — feature-owned dormant destination controller and tests; CI not yet verified.
**Primary owner:** Workout presentation implementation, single remote branch.
**Affected platforms:** Flutter Workout feature only; no user-visible route.

## Owner Approval and Scope

- Existing owner-approved #569 Move behavior. Internal bounded subtask; no new approval trigger.
- Inspect saved Routine via M3A owner/login-cycle/source-Program/revision-bound repository, list only canonical owner Programs, exclude source and duplicates.
- Consume one selection on explicitly confirmed dispatch, re-read owner Programs before write, preserve M3A unknown-outcome semantics and server CAS.
- Out of scope: production Move UI/callback, selector sheet and confirmation rendering, canonical My Program default (#568), +New Program navigation, Create & Move, shared Edit/Delete UI mutex, app shell/provider changes, Supabase DDL/GRANT, release.

## Active Handoff

- Planning owner: GitHub #569; Linear TNYX-81 broad W4 Backlog with existing dependencies.
- Implementation owner: tnyx/issue-569-m3b-existing-program-move-flow (remote branch).
- Review owner: GitHub manual security and Flutter CI.
- Ownership state: Active.
- Repository baseline: protected main 59a21ba305b3265aa8d903dc3f46ee397b39219f after squash-merged PR #595.
- Owner Windows tree: not inspected or altered by remote connector; no assumption of clean local checkout.
- Current source state: M3B1 dormant destination inspection/confirmed dispatch controller with focused tests; no app wiring.
- Validation completed at SHA: none for this new source. Post-merge M3A Flutter CI #39055475888 5/5 PASS on main.
- Validation required: new exact-head Flutter CI, targeted unit tests, manual review; M3B2 UI/route/auth-cycle integration requires separate review.

## Discovery / Architecture

- M1 RPC and M2C cutoff applied (64 migrations); authenticated Move EXECUTE remains revoked.
- Reuse RoutineMoveRepository M3A one-use CAS and ProgramRepository owner-scoped list. No duplicate Program source, no magic name matching.
- The future user-facing selection will show + New Program first only once an executable Program creation path exists, including stable #568 identity semantics where relevant.
- Frontend must inject live owner/login-cycle guard; this controller never opens a modal, grants access or directly changes ProgramId.
- M3B2 still owns sheet/confirmation, app-shell guard, cross-operation Create/Edit/Delete checks, refresh source and destination only after safe outcomes, unknown messaging and device UX tests.

## Quality Review and Handoff

Not validated; do not merge or activate on this brief alone. Record exact-head CI and review evidence before next gate.
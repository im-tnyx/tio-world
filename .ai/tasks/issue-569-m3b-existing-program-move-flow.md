# #569 M3B1 — Owner Program Move destination controller

**Status:** In progress / Draft PR #597 — dormant destination controller source validated at `3e5fb7cdbe0493885dada93d08ee7f2c88aa3010`; manual review and follow-on selector UI remain gated.
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
- Current source state: M3B1 dormant destination inspection/confirmed dispatch controller with 12 focused tests; generation guard prevents canceled/overlapping late owner reads from resurrecting stale selections. No app wiring.
- Validation completed at SHA: [Flutter CI #39056881534](https://github.com/im-tnyx/tio-world/actions/runs/39056881534) **SUCCESS** at `3e5fb7cdbe0493885dada93d08ee7f2c88aa3010`, all five Flutter/Dart jobs plus both attribution checks (7/7). Workout job logs show 726 tests passed including all 12 M3B1 tests. Previous source-only SHA `bf185971` also passed full Flutter CI #39056436950. Post-merge M3A run #39055475888 passed 5/5 on main.
- Validation remaining: current docs-only handoff SHA attribution/CI, independent/manual review, and M3B2 selector/confirmation/app-shell/auth-cycle wiring. No device QA or production Move grant.

## Discovery / Architecture

- M1 RPC and M2C cutoff applied (64 migrations); authenticated Move EXECUTE remains revoked.
- Reuse RoutineMoveRepository M3A one-use CAS and ProgramRepository owner-scoped list. No duplicate Program source, no magic name matching.
- The future user-facing selection will show + New Program first only once an executable Program creation path exists, including stable #568 identity semantics where relevant.
- Frontend must inject live owner/login-cycle guard; this controller never opens a modal, grants access or directly changes ProgramId.
- M3B2 still owns sheet/confirmation, app-shell guard, cross-operation Create/Edit/Delete checks, refresh source and destination only after safe outcomes, unknown messaging and device UX tests.

## Quality Review and Handoff

Source and tests validated at `3e5fb7cd` (not this docs-only follow-up SHA). PR #597 remains Draft and not reviewed for merge. No Move UI, EXECUTE grant, or release; M3B2 must receive its own review and owner rollout gate.
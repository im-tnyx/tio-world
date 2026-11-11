# #569 M3B1 — Owner Program Move destination controller

**Status:** **Validated / archived 2026-10-20.** [PR #597](https://github.com/im-tnyx/tio-world/pull/597) squash-merged as `main@f58fbc34e28110ef8bddfbce14756430b19ada4e` (verified `gh pr list --state merged` on 2026-10-20). Parent [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569) stays OPEN. Production Move stays OFF. The historical status line is not the current handoff.
**Historical status:** **Status:** Draft PR #597 — dormant destination controller validated at exact source+test HEAD `056b0b56d8dfdcb97976dbe3ab7e873005e8c8ae`; cross-PR integration/owner merge gate remains open.
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
- Validation completed at source+test HEAD: [Flutter CI #39058582339](https://github.com/im-tnyx/tio-world/actions/runs/39058582339) **SUCCESS** at `056b0b56d8dfdcb97976dbe3ab7e873005e8c8ae`, all five Flutter jobs, Workout shard 727 PASS, including the new pending-confirmed-destination-read abandonment regression. Prior `3e5fb7cd` CI #39056881534 passed its 12 focused cases; no device QA claimed.
- Validation remaining: this docs-only handoff SHA exact checks, cross-PR combined source validation and owner merge gate. Manual COMMENTED review #597 raised two P2 threads: abandonment race fixed and thread resolved; one controller/UI duplication thread stays open pending integrated #598 review. No device QA or production Move grant.

## Discovery / Architecture

- M1 RPC and M2C cutoff applied (64 migrations); authenticated Move EXECUTE remains revoked.
- Reuse RoutineMoveRepository M3A one-use CAS and ProgramRepository owner-scoped list. No duplicate Program source, no magic name matching.
- The future user-facing selection will show + New Program first only once an executable Program creation path exists, including stable #568 identity semantics where relevant.
- Frontend must inject live owner/login-cycle guard; this controller never opens a modal, grants access or directly changes ProgramId.
- M3B2 still owns sheet/confirmation, app-shell guard, cross-operation Create/Edit/Delete checks, refresh source and destination only after safe outcomes, unknown messaging and device UX tests.

## Quality Review and Handoff

Source and regression tests validated at `056b0b56` (before this docs-only update). PR #597 remains Draft and unmerged. Stacked Draft PR #598 now targets this controller branch and must consume `RoutineMoveDestinationController` rather than duplicate dispatch logic; current Flutter CI runs only for PRs targeting `main`, so stacked integration is NOT yet CI-certified. Keep second P2 ownership thread unresolved until composite CI/review after approved sequencing. No Move UI activation, EXECUTE grant or release.
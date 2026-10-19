# GitHub #569 — M3D3B3e UNKNOWN feedback lifecycle regression

**Status:** In Review — [PR #616](https://github.com/im-tnyx/tio-world/pull/616) Ready for Review; P2 fix requires fresh exact-HEAD CI, owner authorized conditional merge
**Implementation owner:** Workout presentation/widget tests
**Planning and security review:** Repository architecture review + Codex code review
**Branch:** `tnyx/issue-569-m3d3b3e-unknown-ui-lifecycle-regression`
**Base:** Protected `main@173b5d979c5952d1a492c7c050ddcf6b4001920a`
**Related:** GitHub #569, Linear TNYX-81, merged [#615](https://github.com/im-tnyx/tio-world/pull/615)

## Discovery and owner boundary
Owner-approved #569 Move lifecycle includes truthfulness after UNKNOWN responses, auth/login-cycle revocation, owner-scoped list refresh and no blind retry. No new product/UI slice. User first requested work through review gate; on 2026-10-19 the owner separately authorized **Go merge with merge gate**. Merge remains blocked until the fresh P2/P3 review findings are resolved and all new exact-HEAD required checks pass.

**In scope:** Add focused widget regressions for (a) atomic Create & Move UNKNOWN whose optional verifier returns no exact receipt; and (b) widget disposal while a previously dispatched existing Move's receipt is pending. Existing Move/atomic success, preview zero writes and revoked-session tests already exist; avoid duplicating them. Reconcile stale merged #615 handoffs.

**Out of scope:** Production UI geometry, code paths without a demonstrated test failure, 5-second real reversal Undo (separate owner approval required), hosted Supabase SQL/RPC/grants, release activation, backend or hardware QA.

## Actual source/runtime audit
- Root and nested AGENTS, canonical architecture/ownership/dev/roadmap/Supabase docs, feature workflow, task template/index, Workout Move flow and repository tests, GitHub issue #569, Linear TNYX-81 and its blockers read.
- [PR #615](https://github.com/im-tnyx/tio-world/pull/615) merged at protected `main@173b5d979c5952d1a492c7c050ddcf6b4001920a`; [post-merge Flutter CI #39242585331](https://github.com/im-tnyx/tio-world/actions/runs/39242585331) **5/5 SUCCESS**; 0 open PRs at scope start.
- Live read-only Supabase: `move_user_workout_routine` SECURITY DEFINER exists but authenticated/anon EXECUTE false; atomic Create+Move RPC absent. Existing advisor warnings not changed; no database write.
- Production release `routineMoveReleaseEnabledProvider=false`. The current feature `RoutineMoveFlow` rechecks `context.mounted && canWrite()` after awaited verification. A confirmed repository receipt may request caller refresh even when original widget is gone, but cannot show old UI feedback.

## Intended tests
- [x] Atomic UNKNOWN with `RoutineMoveReadbackKind.notConfirmed` (or unavailable) remains unconfirmed; exactly one atomic callback and one readback, no standalone Program create or Move RPC.
- [x] Existing Move UNKNOWN exact receipt arrives after unmount: no stale "Routine moved" UI, no uncaught Flutter exception, exactly one original write and one verification, return flag preserves owner-guarded refresh request. No late retry.
- [x] No production source modifications; only widget test and `.ai` handoff/index edits.
- [ ] Latest exact-HEAD Flutter 5/5 and attribution after P2 fix plus P3 handoff edits. Original `203bb831` [Flutter #39245903335](https://github.com/im-tnyx/tio-world/actions/runs/39245903335) 5/5 SUCCESS and [attribution #39245903069](https://github.com/im-tnyx/tio-world/actions/runs/39245903069) SUCCESS, but **superseded** by the stronger test; new checks pending.
- [ ] Latest-head code review and inline finding resolution; manual review recorded, PR Ready for Review. Codex completed at old HEAD `203bb831` with 0 findings; recheck the new HEAD.
- [x] **Owner `Go merge` authorization received in current turn**; execute only once fresh CI, Codex/disposition and protected-branch gate are clear.

## Current checkpoint
Remote-only GitHub connector; Windows checkout, `git status`, local Flutter tests and physical QA are not available. Use GitHub ancestry, scoped diff and hosted exact-HEAD CI as verifiable evidence.


## Quality review findings and exact-head handoff (2026-10-19)

| ID | Priority | Status | Finding / correction |
| --- | --- | --- | --- |
| [P2 test route + messenger](https://github.com/im-tnyx/tio-world/pull/616) | P2 | Fixed in source `e3aa08cc`; validation pending | Previous test unmounted all of MaterialApp, so feedback assertions were vacuous. Replacement removes just the original Navigator route while keeping a persistent destination Scaffold and the same app-level ScaffoldMessenger; asserts no stale Snackbar after readback and proves messenger alive using a positive-control SnackBar. |
| [P3 task status](https://github.com/im-tnyx/tio-world/pull/616) | P3 | Corrected in this handoff, latest-head review pending | This task now identifies PR #616 Ready for Review, latest code-review status, exact old-head CI evidence and P2 corrective HEAD/new CI requirement. |
| [P3 index](https://github.com/im-tnyx/tio-world/pull/616) | P3 | Pending same-branch index correction | Index must identify PR #616 and distinguish earlier PASS from P2 fix final validation. |

**Current owner:** Workout presentation test implementation; review owner audits but does not modify runtime. Production Move release flag remains OFF, hosted Move EXECUTE revoked, hosted atomic Create+Move absent and true post-commit Undo separately approval gated. No local Windows checkout or physical device QA performed. Follow the live PR and GitHub checks for the final verdict rather than treating this dated checkpoint as a CI pass.

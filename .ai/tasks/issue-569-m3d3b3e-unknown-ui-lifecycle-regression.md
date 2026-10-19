# GitHub #569 — M3D3B3e UNKNOWN feedback lifecycle regression

**Status:** In progress · Review gate not yet reached
**Implementation owner:** Workout presentation/widget tests
**Planning and security review:** Repository architecture review + Codex code review
**Branch:** `tnyx/issue-569-m3d3b3e-unknown-ui-lifecycle-regression`
**Base:** Protected `main@173b5d979c5952d1a492c7c050ddcf6b4001920a`
**Related:** GitHub #569, Linear TNYX-81, merged [#615](https://github.com/im-tnyx/tio-world/pull/615)

## Discovery and owner boundary
Owner-approved #569 Move lifecycle includes truthfulness after UNKNOWN responses, auth/login-cycle revocation, owner-scoped list refresh and no blind retry. No new product/UI slice. User requested continuation **through review gate only**, not merge.

**In scope:** Add focused widget regressions for (a) atomic Create & Move UNKNOWN whose optional verifier returns no exact receipt; and (b) widget disposal while a previously dispatched existing Move's receipt is pending. Existing Move/atomic success, preview zero writes and revoked-session tests already exist; avoid duplicating them. Reconcile stale merged #615 handoffs.

**Out of scope:** Production UI geometry, code paths without a demonstrated test failure, 5-second real reversal Undo (separate owner approval required), hosted Supabase SQL/RPC/grants, release activation, backend or hardware QA.

## Actual source/runtime audit
- Root and nested AGENTS, canonical architecture/ownership/dev/roadmap/Supabase docs, feature workflow, task template/index, Workout Move flow and repository tests, GitHub issue #569, Linear TNYX-81 and its blockers read.
- [PR #615](https://github.com/im-tnyx/tio-world/pull/615) merged at protected `main@173b5d979c5952d1a492c7c050ddcf6b4001920a`; [post-merge Flutter CI #39242585331](https://github.com/im-tnyx/tio-world/actions/runs/39242585331) **5/5 SUCCESS**; 0 open PRs at scope start.
- Live read-only Supabase: `move_user_workout_routine` SECURITY DEFINER exists but authenticated/anon EXECUTE false; atomic Create+Move RPC absent. Existing advisor warnings not changed; no database write.
- Production release `routineMoveReleaseEnabledProvider=false`. The current feature `RoutineMoveFlow` rechecks `context.mounted && canWrite()` after awaited verification. A confirmed repository receipt may request caller refresh even when original widget is gone, but cannot show old UI feedback.

## Intended tests
- [ ] Atomic UNKNOWN with `RoutineMoveReadbackKind.notConfirmed` (or unavailable) remains unconfirmed; exactly one atomic callback and one readback, no standalone Program create or Move RPC.
- [ ] Existing Move UNKNOWN exact receipt arrives after unmount: no stale "Routine moved" UI, no uncaught Flutter exception, exactly one original write and one verification, return flag preserves owner-guarded refresh request. No late retry.
- [ ] No production source modifications unless tests expose a real defect.
- [ ] Exact-HEAD Flutter analyzer/app-workout/core-wear/nutrition/aggregate CI 5/5 and commit attribution.
- [ ] Codex latest-head code review, manual security review, zero unresolved threads and Ready for Review.
- [ ] **No merge without separate owner `Go merge`.**

## Current checkpoint
Remote-only GitHub connector; Windows checkout, `git status`, local Flutter tests and physical QA are not available. Use GitHub ancestry, scoped diff and hosted exact-HEAD CI as verifiable evidence.

# GitHub #569 — M3D3B3d cross-path UNKNOWN mutation receipt regression

**Status:** **Validated / archived 2026-10-20.** [PR #615](https://github.com/im-tnyx/tio-world/pull/615) squash-merged as `main@173b5d979c5952d1a492c7c050ddcf6b4001920a` (verified `gh pr list --state merged` on 2026-10-20). Parent [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569) stays OPEN. Production Move stays OFF. The historical status line is not the current handoff.
**Historical status:** **Status:** Validated · [PR #615](https://github.com/im-tnyx/tio-world/pull/615) squash merged; protected main 173b5d97; post-merge CI 5/5 PASS
**Primary owner:** Workout data / repository tests
**Affected platforms:** Flutter Android/iOS Workout package (tests only)

## Owner Approval and Scope Boundary
**Trigger:** None — regression coverage within owner-approved [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569) Move UNKNOWN handling; no independently scoped product feature, visual change, or DB shape.
**Approval status:** Not required for a normal bounded safety-test subtask.
**Approval evidence:** owner-approved #569 Move existing and atomic lifecycle, same-command UNKNOWN attribution. The 2026-10-19 request asks next work through review gate, not merge.
**Approved boundaries:** Cover both cross-variant directions of the existing old-receipt misattribution invariant.
**Explicit non-changes:** No Flutter production source change unless test exposes a real defect. No UI geometry, 5-second real Undo (separately unapproved), Supabase SQL/RPC/DDL/grant/deploy, release flag, backend, or app shell.

## Active Handoff
**Planning owner:** Tio-world repository audit
**Implementation owner:** Workout data/repository test only
**Review owner:** Codex and author-side manual security review
**Implementation ownership state:** Completed bounded test-only slice; no active source owner
**Repository state last verified:** 2026-10-19, protected `main@428e2c6506533b2b4aecf0ae7f3b94835171f438` with 0 open PRs.
**Branch:** `tnyx/issue-569-m3d3b3d-cross-path-receipt-regression`
**Merged SHA:** `173b5d979c5952d1a492c7c050ddcf6b4001920a`; PR reviewed source HEAD `35729fdfd9233ad2b9408117f6092737dea01309`
**Observed working-tree state:** not available via remote-only GitHub connection; no local checkout was changed.
**PR / tracker:** [Merged PR #615](https://github.com/im-tnyx/tio-world/pull/615) / #569 / Linear TNYX-81 (Backlog; W1/W3 dependencies retained).
**Current implementation state:** Both cross-operation tests merged and passed in Flutter app-workout CI; no production-source files changed. Three scoped paths.
**Validation completed at SHA:** [post-merge #614 Flutter CI #39238953843](https://github.com/im-tnyx/tio-world/actions/runs/39238953843) SUCCESS 5/5 at base.
**Validation completed:** Reviewed HEAD `35729fdf`: [Flutter CI #39240571900](https://github.com/im-tnyx/tio-world/actions/runs/39240571900) 5/5 SUCCESS, [attribution #39240569855](https://github.com/im-tnyx/tio-world/actions/runs/39240569855) SUCCESS, Codex code review completed 0 findings, 0 inline threads. [Main post-merge CI #39242585331](https://github.com/im-tnyx/tio-world/actions/runs/39242585331) 5/5 SUCCESS at merge SHA. No separate automatic security review claimed.
**Current blocker:** none for this test-only approved subtask.
**Next exact action:** None for B3d; follow-on M3D3B3e test-only workflow owns its new branch/review checkpoint.

## 1. Discovery
**User outcome:** A previous ambiguous existing Move must never authorize a newer *atomic Create & Move* that was refused before dispatch, and vice versa.
**Success criteria:** Each permutation has exactly 1 first RPC; attempted second RPC is denied by same-Routine UNKNOWN hold; only first command mutation UUID can verify the earlier persisted revision/destination; mismatched token causes 0 additional owner read/write; later original-command exact proof releases the hold; fresh revision can safely dispatch an ordinary new Move.
**Scope:** Workout repository regression tests + this task handoff and index reconciliation for merged PR #614.
**Non-goals:** production change, real Undo, hosted atomic deployment or release.

## 2. Codebase Exploration
**Verified evidence:** `SupabaseRoutineMoveRepository` uses shared `RoutineMoveAttemptGate` across both `move` and `createAndMove`; `verifyUnknown` requires current command mutationId, matches frozen attempt before owner read, and releases hold only after authoritative revision advance. PR #614 merged to `main@428e2c6506533b2b4aecf0ae7f3b94835171f438`; latest post-merge CI 5/5. Existing focused regression covers existing→existing, not both cross variants.
**Backend evidence:** Live Supabase read-only confirms `move_user_workout_routine` exists but authenticated/anon EXECUTE false; atomic Create+Move absent; auth SELECT columns exist. Security Advisor warnings are independent of test-only slice.
**Review boundaries:** root and nested `AGENTS.md`, feature workflow, canonical docs, .ai/task, issue #569, Linear TNYX-81/TNYX-267, repo tests read.

## 3. Clarification
**Decision:** Reuse `FakeMoveGateway`, real repository logic and shared gate; no mocks for repository contract itself. Test two cross-operation permutations with the same mutation receipt and distinct new UUID.

## 4. Architecture Design
**Path:** fake owner data → Workout repository dispatch guards → old UNKNOWN hold → second cross-path pre-dispatch rejection → owner readback with current-command correlation.
**Alternative rejected:** Second RPC retry, optimistic UI success, new server verification API, real Undo, and broader app-shell wiring.
**Failure/accessibility:** test-only/no rendered UI. Denied second attempt remains unconfirmed; legacy older command can be confirmed only by its exact persisted receipt.

## 5. Implementation Plan
- [x] Add both cross-variant regressions and assert no owner read on mismatched token; verified by exact-head Flutter app-workout tests.
- [x] Reconcile merged PR #614 with post-merge Flutter 5/5 and #615 active handoff in task index.
- [x] Exact latest-head Flutter CI 5/5 and attribution success.
- [x] Codex code review zero findings, author-side manual security COMMENT (not independent APPROVED); standard GitHub squash merge completed on separate owner authorization.

## 6. Quality Review
Review and 5/5 Flutter validation completed on exact HEAD. No independent APPROVED review recorded. No device QA or live RPC activation claimed.

## 7. Final Handoff
**Actual behavior:** no production change.
**Final status:** VALIDATED / MERGED; production Move release remains OFF.

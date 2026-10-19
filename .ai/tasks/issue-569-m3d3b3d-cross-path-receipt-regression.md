# GitHub #569 — M3D3B3d cross-path UNKNOWN mutation receipt regression

**Status:** In progress · test-only, audit-first
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
**Implementation ownership state:** Active
**Repository state last verified:** 2026-10-19, protected `main@428e2c6506533b2b4aecf0ae7f3b94835171f438` with 0 open PRs.
**Branch:** `tnyx/issue-569-m3d3b3d-cross-path-receipt-regression`
**HEAD SHA:** starts at `428e2c6506533b2b4aecf0ae7f3b94835171f438` (update after commits)
**Observed working-tree state:** not available via remote-only GitHub connection; no local checkout was changed.
**PR / tracker:** #569 / Linear TNYX-81 (Backlog; W1/W3 dependencies retained).
**Current implementation state:** test-only slice starting.
**Validation completed at SHA:** [post-merge #614 Flutter CI #39238953843](https://github.com/im-tnyx/tio-world/actions/runs/39238953843) SUCCESS 5/5 at base.
**Validation remaining:** latest-head app-workout/analyzer/core-wear/nutrition CI; attribution; Codex review; manual diff.
**Current blocker:** none for this test-only approved subtask.
**Next exact action:** add two opposite-path race/receipt regressions; run hosted CI then review gate; no merge.

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
- [ ] Add both cross-variant regressions and assert no owner read on mismatched token.
- [ ] Reconcile stale PR #614 task index on branch.
- [ ] Exact latest-head CI and attribution.
- [ ] Codex/manual review, ready-for-review gate, no merge.

## 6. Quality Review
Not run yet. No independent approval claimed.

## 7. Final Handoff
**Actual behavior:** no production change.
**Final status:** REVIEW pending.

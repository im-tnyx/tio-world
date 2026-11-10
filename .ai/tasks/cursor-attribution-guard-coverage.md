# Feature Task: Cover Cursor AI co-author attribution in commit guard

**Status:** Validated
**Working agent:** Cursor
**Affected platforms:** Repository governance / CI only

Agent identity for this slice is recorded in this task file only. Do **not** put AI `Co-authored-by` trailers on git commits.

## Owner Approval and Scope Boundary

**Trigger:** None (governance/CI correctness inside existing TNYX-232 attribution guard; product owner explicitly directed on 2026-11-10)
**Approval status:** Approved
**Approval evidence:** Product-owner chat: Cursor co-author appeared despite no-co-author rule; CI passed because Cursor was not on deny-list; product owner replied to extend deny-list and rewrite dirty commits with `Yes ye bhi sahi karna hoga`.
**Approved boundaries:** Extend `scripts/check_commit_attribution.sh` (+ tests) to reject Cursor / cursor.com / cursoragent.com attribution trailers; strip existing Cursor trailers from PR #740 commits; update CONTRIBUTING mention. No product UI change.
**Explicit non-changes:** No Flutter/UI redesign; no Supabase schema; no merge of PR #740; no weakening of existing Claude/OpenAI detection.

## Active Handoff

**Planning agent:** Cursor
**Implementation agent:** Cursor
**Review agent:** Independent GitHub reviewer (`im-tio`) when re-requested
**Implementation ownership state:** Complete for this governance slice
**Branch:** feat/w7c-3-active-workout-execution-ui
**HEAD SHA:** record on push
**PR / tracker:** GitHub PR #740
**Current implementation state:** Deny-list + fixtures landed; Cursor trailers rewritten off #740 history; unit tests 20/20 passed.
**Current blocker:** `pull_request_target` attribution runner still executes the checker from `main`, so Cursor deny-list only enforces on future PRs after this script reaches `main`.
**Next exact action:** Keep agent identity updates in `.ai/tasks/*` only; no AI commit trailers.

## 1. Discovery

### User Outcome

Cursor auto-trailers are rejected like Claude/OpenAI, and existing Cursor trailers on #740 are removed. Which agent did the work stays visible in this MD file, not in git trailers.

### Success Criteria

- Deny-list includes Cursor display name and cursor.com / cursoragent.com domains
- Fixture tests cover pass/fail for Cursor
- No `Co-authored-by: Cursor` remains on `origin/main..HEAD` for PR #740
- Attribution unit test script passes
- Task MD names the working agent (`Cursor`) instead of inventing commit co-authors

### Non-Goals

- Broader rewrite of unrelated history
- Changing squash-merge GitHub UI behavior
- Treating the product owner and the working agent as the same role in task text

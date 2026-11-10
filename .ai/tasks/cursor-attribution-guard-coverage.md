# Feature Task: Cover Cursor AI co-author attribution in commit guard

**Status:** In progress
**Primary owner:** Current local agent (owner-directed)
**Affected platforms:** Repository governance / CI only

## Owner Approval and Scope Boundary

**Trigger:** None (governance/CI correctness inside existing TNYX-232 attribution guard; owner explicitly directed on 2026-11-10)
**Approval status:** Approved
**Approval evidence:** Owner chat: Cursor co-author appeared despite no-co-author rule; CI passed because Cursor was not on deny-list; owner replied to extend deny-list and rewrite dirty commits with `Yes ye bhi sahi karna hoga`.
**Approved product/UI/data-shape boundaries:** Extend `scripts/check_commit_attribution.sh` (+ tests) to reject Cursor / cursor.com / cursoragent.com `Co-authored-by` trailers; strip existing Cursor trailers from PR #740 commits; update CONTRIBUTING mention. No product UI change.
**Explicit non-changes:** No Flutter/UI redesign; no Supabase schema; no merge of PR #740; no weakening of existing Claude/OpenAI detection.

## Active Handoff

**Implementation owner:** Current local agent
**Implementation ownership state:** Active
**Branch:** feat/w7c-3-active-workout-execution-ui
**PR / tracker:** GitHub PR #740 (history cleanup) + attribution script landing with this branch; guard runtime continues to load checker from `main` until merge
**Current blocker:** `pull_request_target` attribution runner always executes the checker from `main`, so Cursor deny-list only enforces on future PRs after this script reaches `main`
**Next exact action:** Land script/tests, rewrite Cursor trailers off #740 commits, force-push with lease

## 1. Discovery

### User Outcome

Cursor auto-trailers are rejected like Claude/OpenAI, and existing Cursor trailers on #740 are removed.

### Success Criteria

- Deny-list includes Cursor display name and cursor.com / cursoragent.com domains
- Fixture tests cover pass/fail for Cursor
- No `Co-authored-by: Cursor` remains on `origin/main..HEAD` for PR #740
- Attribution unit test script passes

### Non-Goals

- Broader rewrite of unrelated history
- Changing squash-merge GitHub UI behavior
- Product/runtime Flutter changes in this slice beyond already-approved Play fix coexistence on the same branch

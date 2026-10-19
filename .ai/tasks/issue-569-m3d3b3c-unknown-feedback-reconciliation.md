# GitHub #569 — M3D3B3c UNKNOWN Move flow readback feedback

**Status:** Ready for Review gate (PR #614; no merge). Exact-HEAD CI and review evidence are tracked in the live PR, not assumed here.
**Implementation owner:** Workout presentation / RoutineMoveFlow
**Related:** GitHub #569, merged [PR #613](https://github.com/im-tnyx/tio-world/pull/613), Linear TNYX-81
**Base:** protected `main@a892e2dbabf19d771234f3e1d8f94d8f2c58a544`; branch `tnyx/issue-569-m3d3b3c-unknown-feedback-reconciliation`
**Owner scope:** Existing owner-approved Move Routine confirmation and truthful UNKNOWN reconciliation. User asked to start next work through review gate on 2026-10-19; no separate product-visible redesign or schema change.

## Audit / reality
- Read root `AGENTS.md`, `apps/features/AGENTS.md`, canonical docs, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, post-merge and push/PR templates, GitHub #569 and Linear TNYX-81 / TNYX-267.
- Fresh [main post-merge Flutter CI #39229765962](https://github.com/im-tnyx/tio-world/actions/runs/39229765962) **5/5 SUCCESS** on `main@a892e2dbabf19d771234f3e1d8f94d8f2c58a544`; no open PR at slice start.
- Merged `RoutineMoveUnknownVerifier.verifyUnknown` is a read-only same-owner/login-cycle mutation UUID + destination + expected revision+1 check, and releases the in-process uncertainty hold only after a later persisted revision.
- Existing `RoutineMoveFlow` catches UNKNOWN, always shows unconfirmed and returns caller-guarded refresh=true after a dispatched attempt, never invokes the optional verifier.
- Supabase live read-only: existing Move SECURITY DEFINER RPC `authenticated EXECUTE=false`, hosted atomic Create+Move absent. Production release flag false and preview 0 writes. Advisor existing warnings outside scope; do not broaden.

## Chosen narrow design
- If a confirmed write attempt throws `RoutineMoveOutcomeUnknown`, and current route owner/auth cycle is still eligible, optionally invoke `RoutineMoveUnknownVerifier.verifyUnknown(routine.id, mutationId: currentCommandToken)` ONCE.
- Only `RoutineMoveReadbackKind.confirmedLatestMutation` may reuse the existing `Routine moved.` feedback (the repository already validates owner/cycle, UUID, destination, revision). Any absent, unchanged, superseded, read-unavailable, unsupported or thrown readback retains `Move status is unconfirmed. Refresh Programs; do not retry.`.
- Recheck `context.mounted` / `canWrite()` AFTER awaited read; stale cycle never displays either feedback; return `attempted` for caller owner-cycle-scoped refresh regardless. No optimistic or new storage. Both existing Program and atomic Create+Move paths share this catch.
- A fresh command can be rejected before dispatch by the old UNKNOWN hold. The verifier MUST additionally compare the caller-supplied command UUID to its frozen UNKNOWN UUID **before any owner read**; never attribute a previous command's receipt to a newer one. This is a P2 correctness fail-closed guard; regression covered at repository and presentation tests.
- Keep preview-only Undo dismiss-only; do not introduce real reverse Move, timer changes, error spam, more RPC retries, hosted deployment or app-shell wiring. This only reuses existing UI copy and avoids false success.

## Review and quality gates
- [x] Focused widget test sources added for exact-token existing/atomic readback, four negative result kinds, verifier exception, auth switch and preview zero-write; execution PASS must be established from live exact-HEAD CI.
- [ ] Before merge: recheck latest exact-head Flutter 5/5 and attribution in [PR #614](https://github.com/im-tnyx/tio-world/pull/614). Initial `402d3192` analyzer failed (optional verifier narrowing and chained async throw); follow-up `47145466` analyzer found one `prefer_const_constructors` lint at test line 916. Fix committed as `46fd922b`; later documentation-only edits require their own exact-HEAD CI.
- [ ] Latest-head architecture/security review and Codex findings/thread disposition. Codex quota issues are external service failures, not green review.
- [ ] At final gate: PR #614 Ready for Review, latest branch compare and zero unresolved inline review threads. **No actual merge** without separate owner `Go merge`.
- Local Windows checkout, phone QA and Flutter CLI unavailable in the connected GitHub runtime. Never report those run.

## Recovery checkpoint
- Owner requested **review gate only**; PR #614 started Draft, source review and CI fixes applied sequentially. `main@a892e2db` held while work proceeded. No local Windows sync or branch deletion carried out.
- Production Workout change is contained to existing `RoutineMoveFlow` UNKNOWN error catch, without a new widget/token. All other code paths and preview stay unchanged.
- Original analyzer failures are real validation issues and fixed in subsequent scoped commits. Further author-side P2 security review found old-receipt misattribution risk: current-command UUID binding was added across Workout domain, adapter, flow and repository/widget tests. No blanket success claim until the final HEAD CI and code review complete.

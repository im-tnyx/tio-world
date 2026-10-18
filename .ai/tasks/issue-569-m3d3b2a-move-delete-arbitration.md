# #569 M3D3B2a — Routine Move/Delete cross-operation arbitration

**Status:** Review handoff (scoped source + tests green; reviewer gate separate from merge)
**Primary owner:** Workout feature repository/data adapters; app-shell dependency composition only
**Affected platforms:** Flutter Android/iOS shared Workout; no visual/UI changes

## Owner Approval and Scope Boundary
**Trigger:** None beyond previously approved #569 implementation; owner said `Go next` after M3D3B2 read-only audit (2026-10-19).
**Scope:** Prevent one owner's Move (existing or atomic Create+Move) and Delete from dispatching concurrently against the *same RoutineId* through independent adapters/routes. Pin a single shared per-owner Routine process gate across repository recreation and login cycles. Preserve UNKNOWN until a later owner-verified revision proves old CAS obsolete.
**Excluded:** Edit/Create coordination (M3D3B2b), destination/Program refresh (M3D3B3), real 5-second post-commit Undo, visual/UI changes, Supabase migrations/EXECUTE or production Move activation.
**Owner of implementation:** One implementation slice, Workout feature adapter code + app provider composition + tests. No concurrent source editor.

## Audit evidence
- Start from protected `main@4dba419f8181cf739832ae556472f91fe87a92a4` (squash PR #608, unrelated iOS-only platform build). Zero open GitHub PRs at branch creation.
- `AGENTS.md`, nested feature `AGENTS.md`, `.ai/workflow.md`, feature workflow, architecture/ownership, ADR-0015, #569, TNYX-81, actual Move/Delete adapters, in-memory attempt gates, app providers and tests inspected.
- Current Move and Delete each have an owner+Routine in-flight/UNKNOWN gate, but no shared cross-operation gate. Both protected server RPCs use owner/revision checks, so client process arbitration is additional safety, not a substitute for RPC locks/CAS.
- Hosted Supabase `move_user_workout_routine` authenticated EXECUTE=false; atomic Create+Move not hosted, production Move release provider hard false. No hosted changes intended.
- No local Windows worktree/Flutter executable available via this remote connector; use exact GitHub CI for validation and report its actual status.

## Seven-phase workflow
1. **Discovery:** prevent same-owner Move vs Delete overlap/uncertain-replay before actual Move capability release.
2. **Exploration:** Move/Delete adapters own separate process gates; app composition reuses each within ProviderContainer; GitHub #569 requires competing Delete safety.
3. **Decision:** introduce one narrowly scoped, owner/Routine-keyed *cross-operation* process guard in Workout data, injected into both adapters from the app composition; keep individual one-use and auth-cycle protections.
4. **Architecture:** reserve synchronously immediately before either RPC; invalidate already-inspected opposite-action tokens via shared dispatch generation; block UNKNOWN until positive later-revision owner read. No implicit rollback, optimistic success or new server source of truth.
5. **Implementation:** gate + adapter injection and checks + provider wiring + race tests. Use no UI changes. Cross-op Edit/Create remains a separately scoped slice.
6. **Quality:** source/test HEAD `495b7c01b4353b36767020a20efeadf9c0d7b602` [Flutter CI #39174717198](https://github.com/im-tnyx/tio-world/actions/runs/39174717198) **5/5 SUCCESS** and [Commit attribution #39174715719](https://github.com/im-tnyx/tio-world/actions/runs/39174715719) **2/2 SUCCESS**. Earlier CI #39174417169 failed due a test fixture optional-parameter syntax error at line 118; fixed by `495b7c01`, latest source/test HEAD green. Manual diff/security audit saw no confirmed blocking source finding; Codex review and independent `APPROVED` require separate verification.
7. **Handoff:** PR review gate; separate owner `Go merge` required. Preserve production Move OFF and hosted grants revoked.

**Branch:** `tnyx/issue-569-m3d3b2a-move-delete-arbitration` from `main@4dba419f`.
**Next:** Verify any later handoff-only HEAD checks before Ready for Review. Inspect Codex/independent inline review and resolve P1/P2; separate owner `Go merge` mandatory. No merge authorization.

## Review gate checklist (source/test checkpoint)
- [x] Base `main@4dba419f8181cf739832ae556472f91fe87a92a4` and 9 scoped files; 0 behind parent at review start.
- [x] Feature-owned gate preserves single operation per owner/Routine, UNKNOWN revision evidence, stale token invalidation; app shares one provider lifetime; no auth/RLS/RPC or live flag changes.
- [x] Tests for Move→Delete, Delete→Move, atomic Create+Move→Delete, in-flight read race, UNKNOWN from both sides, same vs later revision, owner isolation and provider lifetime.
- [x] Source/test HEAD `495b7c01` Flutter CI 5/5, attribution 2/2.
- [ ] Any later docs-only HEAD: exact-head CI + required attribution.
- [ ] Codex reviewer/final result, disposition of any P1/P2 inline findings and repository merge policy (formal approval not implied).
- [ ] Owner's separate `Go merge`.

**Truth boundary:** no hosted Move grant, no atomic Create+Move SQL deployment, no production Move enablement, no local Windows checkout/Flutter runner. Older task index #607 'review pending' state was reconciled separately against GitHub merge and owner device QA, not treated as live source.

# #569 M3D1 — Dormant Move app providers

**Status:** In progress
**Primary owner:** apps/app composition
**Affected platforms:** Flutter phone internal providers; no visible UI

## Owner Approval and Scope Boundary
- **Trigger:** None; bounded subtask under approved GitHub #569 and Linear TNYX-81.
- **Approval evidence:** User Go with agent.md; parent Move scope; merged PR #601.
- **Allowed:** ProviderContainer-lifetime Move attempt gate, single Move flow, auth/login-cycle-bound Supabase Move adapter shared with the atomic capability, focused tests.
- **Excluded:** app-shell 3-dot activation, database migration/grants, Default My Program, UI redesign, cross-operation release rollout.

## Active Handoff
- **Implementation owner:** app composition (this branch only)
- **Review owner:** independent review pending
- **Base:** protected main b53c330303503a91b7b6131999095a21f63ebb8e (post-merge Flutter CI succeeded)
- **Branch:** tnyx/issue-569-m3d1-move-app-providers
- **Environment:** GitHub connector only; Windows local git status unavailable. No destructive sync or physical test claimed.
- **Current scope:** app/composition/workout_providers.dart and app-focused provider tests. Only one active implementation slice.
- **Live DB last verified:** 64 migrations, new atomic RPC absent, Move client grant denied. All client Move actions stay dormant.
- **Remaining validation:** exact-head Flutter CI, independent review; no merge authorization.

## Discovery and Architecture
Use the existing Workout Delete provider pattern: match authoritative Auth user with Supabase client user; fail closed for unavailable/loading/error or missing login cycle. Preserve a shared gate and flow across repository refresh; injected live callback must re-read session each operation. Workout owns RPC and business logic; app owns injection. No new data model, no fake success or two-RPC move. Reuse existing Core UI in later separately reviewed M3D2 only.

## Implementation Plan
- [ ] Add Move gate, flow, and session-bound Move repository with atomic alias.
- [ ] Add tests for absent/mismatched sessions, changing login cycle, shared identity.
- [ ] Verify CI and review, update handoff. No merge/deploy.

## Quality Review
Not run for this slice yet.

## Final Handoff
Pending source and test results. **Status REVIEW**, no activation.

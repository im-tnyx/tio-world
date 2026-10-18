# #569 M3D1 — Dormant Move app providers

**Status:** In Review — [PR #602](https://github.com/im-tnyx/tio-world/pull/602) Open / Ready for Review / unmerged. Exact preceding HEAD `70291762c6cdf1bb9234c09026630a39a62de926` [Flutter CI #39128199802](https://github.com/im-tnyx/tio-world/actions/runs/39128199802) 5/5 SUCCESS plus 2/2 attribution = **7/7 PASS**. Separate independent APPROVED review and owner merge gate pending.
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
- **Remaining validation:** This follow-up documentation-only HEAD CI after commit; independent APPROVED security/code review and explicit owner Go merge. Previously validated exact head `70291762` CI 7/7 PASS; source/test head `58aea265` also 7/7 PASS.

## Discovery and Architecture
Use the existing Workout Delete provider pattern: match authoritative Auth user with Supabase client user; fail closed for unavailable/loading/error or missing login cycle. Preserve a shared gate and flow across repository refresh; injected live callback must re-read session each operation. Workout owns RPC and business logic; app owns injection. No new data model, no fake success or two-RPC move. Reuse existing Core UI in later separately reviewed M3D2 only.

## Implementation Plan
- [x] Add Move gate, flow, and session-bound Move repository with atomic alias.
- [x] Add tests for missing/mismatched session, same-owner relogin, stale captured repository, A→logout→B and shared alias identity; source/test CI 7/7 PASS.
- [x] Validate source/test HEAD 58aea265 with Flutter CI #39127809266 and attribution (7/7 SUCCESS), and reply/resolve all three reviewed P2/P3 threads.
- [x] Previous documentation-only HEAD `70291762` [Flutter CI #39128199802](https://github.com/im-tnyx/tio-world/actions/runs/39128199802) 5/5 PASS + attribution 2/2 PASS; all three earlier inline findings resolved.
- [ ] Exact later governance-only HEAD CI, independent APPROVED security/code review and explicit owner Go merge. No merge/deploy.

## Quality Review
Original provider/test commit cd56223a: Flutter CI #39126515604 5/5 SUCCESS plus attribution 2/2 SUCCESS. Auth-transition test and handoff HEAD 58aea265: Flutter CI #39127809266 completed 5/5 SUCCESS plus attribution 2/2 SUCCESS. All original 3 PR #602 inline P2/P3 threads replied and RESOLVED. Fresh manual re-review at exact `70291762` found no confirmed new P1/P2; the newer P3 handoff-status finding remained open until this correction. Codex review failed before analysis due usage quota, which is not a security PASS. Independent APPROVED review still pending; source is not app-shell release ready.

## Final Handoff
Provider composition and focused test updates committed. No app-shell routing or UI activation; no Supabase schema/grants. Changed-area tests passed at `58aea265`, prior exact latest HEAD `70291762` 7/7 PASS; this governance-only follow-up HEAD will need its own checks. No app-shell callback, hosted grants or user-visible activation. **Status REVIEW / MERGE HOLD** until independent review and explicit owner Go merge.

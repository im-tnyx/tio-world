# #569 M3B2B1 — Dormant Move to New Program selection UI

**Status:** In review, [Draft PR #600](https://github.com/im-tnyx/tio-world/pull/600); no live Move activation.
**Primary owner:** Workout feature/presentation, single implementation owner for this bounded slice.
**Affected platforms:** Flutter phone, both Program Detail and expanded Library once later app shell wiring enables Move.

## Owner Approval and Scope Boundary
**Trigger:** Existing owner-approved Move Routine #569 first-row `+ New Program` and canonical Create Program name flow; user said "Go with follow agent.md" following #599 merge.
**Approval status:** Approved for this existing bounded feature.
**Approval evidence:** GitHub #569 owner 2026-10-17; Linear TNYX-81/TNYX-267; user current Go.
**Approved product/UI:** `+ New Program` first selectable row; source-only destination list shows that entry, no fake empty rows; reuse existing Create Program name editor without premature program INSERT; explicit `Create & Move` confirmation; app remains dormant until owner-safe atomic client capability and app-shell integration are independently delivered.
**Explicit non-changes:** No database migration/deployment, no `EXECUTE` grant, no standalone Routine truth, no new Create Program editor design or tokens, no #568 My Program identity, no Change Picture/Duplicate, no live app shell wiring, no merge.

## Active Handoff
**Planning owner:** Workout architecture.
**Implementation owner:** Workout feature.
**Review owner:** independent PR review pending.
**Implementation ownership state:** Active.
**Repository state last verified:** protected `main@2c5a2638fdb3eba7daef27a91eb09415fda9543b` after merged #599; zero open PRs at start; hosted Supabase 64 migrations, atomic Create+Move function not deployed; existing Move EXECUTE revoked.
**Branch:** `tnyx/issue-569-m3b2b-dormant-new-program-selector`.
**Observed working-tree state:** GitHub connector branch only; local Windows `git status` unavailable. No assumption of local worktree cleanliness.
**PR / tracker:** [Draft PR #600](https://github.com/im-tnyx/tio-world/pull/600), GitHub #569, Linear TNYX-81, TNYX-267, #568 separately gated.
**Current implementation state:** Source/test `055d887e` implemented the dormant selector; Codex P2 post-dispatch auth switch refresh issue in PR #600 fixed at source/test `b31ccc28` for both New and existing Program paths; three new focused widget regressions added. App remains unwired and Supabase RPC grant is still revoked.
**Validation completed at SHA:** Code/test HEAD `055d887e1960fae1d6e9da514b97d8b0d2bb18bb`: [Flutter CI #39101518706](https://github.com/im-tnyx/tio-world/actions/runs/39101518706) COMPLETED SUCCESS 5/5 (analyzer and all Flutter test shards); commit attribution guard 2/2 SUCCESS.
**Validation remaining:** Re-run exact docs-only handoff HEAD Flutter CI, independent GitHub APPROVED review or policy disposition, explicit owner merge authorization; local Windows and physical device QA not run. Hosted activation separately gated.
**Current blocker:** Actual protected Create+Move client gateway/app shell and Supabase release remain separate.
**Open review finding IDs:** None after disposition. Codex P2 [PRRT_kwDOTOXwB86tn0tg](https://github.com/im-tnyx/tio-world/pull/600#discussion_r4305930495) confirmed, fixed at `b31ccc28`, validated with [Flutter CI #39102545276](https://github.com/im-tnyx/tio-world/actions/runs/39102545276) all 7/7 exact-source/handoff HEAD `8e1b961d` checks SUCCESS, replied and resolved. Independent `APPROVED` review still absent.
**Next exact action:** Verify the subsequent docs-only handoff HEAD CI, recheck reviews/new findings, obtain independent review and separate owner `Go merge`. Do not connect the atomic callback, deploy or grant EXECUTE.

## 1. Discovery
User outcome: Saved Routine Move can choose either another existing owner Program or the first-row `+ New Program` and edit `Program N` name before explicit Create & Move.
Success: No empty destination artifact, no writes on cancel, same protected source Routine target, new name submitted only to future atomic callback; original existing Program Move path unchanged.
Non-goals: No production unlock or hosted mutation.

## 2. Codebase Exploration
`RoutineMoveFlow` from merged #598 provides existing target select and confirmation. `RoutineMoveDestinationController` revalidates persisted eligible Programs, one-use source. `ProgramsSurface._CreateProgramSheet` is canonical generated-name UI, presently performs `ProgramsController.create` standalone INSERT. `ProgramsController.suggestedName` enumerates Program N. Reuse that UI but use name-only mode for Move; never call standalone Program create in Move.

## 3. Clarification
Approved via #569: source-only Move list shows New Program only, no phantom My Program. The M3B2A SQL RPC is merged dormant, but has no deployed permissions. Keep `+ New Program` in the feature's dormant flow only when a real injectable atomic capability exists; do not wire it in apps/app for now.

## 4. Architecture Design
`RoutineMoveFlow` manages modal and draft name. Existing `ProgramsSurface` owns the name editor and a reusable name-only prompt. `RoutineMoveDestinationController` remains the owner read/revalidation for existing destinations. New Program destination sends a single frozen source/ProgramID/mutation tuple to an injected future server-atomic callback only after confirmation. Server remains sole mutation authority. No two-call ProgramRepository.create then Move.

## 5. Implementation Plan
- [x] Reuse canonical Create Program name sheet in name-only mode; existing Create path preserved.
- [x] Add optional New Program first row when a future atomic callback is injected, including source-only lists.
- [x] Explicit Create & Move confirmation; frozen Program ID/mutation token for that attempt; no two-client-write fallback.
- [x] Two new Flutter widget regressions for New Program order and source-only cancellation, plus pre-existing Move regression suite.
- [x] Code/test HEAD Flutter CI #39101518706 PASS 5/5 and required attribution PASS 2/2.
- [x] Codex P2 review finding reproduced in post-dispatch control flow and source fix committed `b31ccc28`; three new auth-switch success/uncertain regressions added, including existing-Program parity.
- [x] Codex P2 thread replied and resolved after current-code tests passed; exact HEAD `8e1b961d` CI #39102545276 all 7/7 SUCCESS.
- [ ] Latest handoff-only HEAD CI and fresh review gate; independent source/security/UI review and explicit owner Go merge.
- [ ] App-shell auth/operation mutex, protected atomic backend adapter, deployed migration, client grants, #568 and physical QA as separate slices.

## 6. Quality Review
**Remote CI:** source/test `055d887e` [Flutter CI #39101518706](https://github.com/im-tnyx/tio-world/actions/runs/39101518706) completed SUCCESS: analyzer, app-workout, core-wear, nutrition-onboarding and aggregate 5/5; required commit attribution + runner 2/2. No local Windows `git status`, local `flutter`, or device QA possible with connector-only session.
**Manual scoped code audit:** six intended paths; no SQL or apps/app diff, optional callback not provided by production; existing destination route unchanged, name-only editor never calls `ProgramRepository.create`. Codex P2 identified session change after dispatched atomic callback, where a committed mutation erroneously returned false and blocked caller refresh. `b31ccc28` changes both atomic and existing Move post-dispatch return paths and UNKNOWN/error handling to preserve `attempted` while suppressing old-session success/unknown messages, with three widget regression tests. Exact P2 fix **Flutter CI #39102545276 completed SUCCESS 7/7 at `8e1b961d`**, including the changed app-workout tests. No original-user success feedback is shown after auth changes. Future activation still requires shared process-lifetime concurrency/unknown gates and app-shell owner/session guards. Independent approval not claimed.

## 7. Final Handoff
**Changed paths:** `programs_controller.dart`, `programs_surface.dart`, `routine_move_flow.dart`, `routine_move_flow_test.dart`, this handoff and `.ai/tasks/README.md`.
**Actual behavior:** New Program path is opt-in via an injected future atomic callback, not callable from the app. It prompts the existing editor for an editable name without writing, then confirms Create & Move. Existing destination flow remains.
**Known limits:** In-flight and uncertain-result cross-operation protection must be implemented in real atomic client adapter; #568 default My Program, app-shell wiring, Supabase rollout and device QA still pending.
**Final status:** REVIEW (code fix validated and P2 thread resolved; independent APPROVED review/owner merge gate outstanding). **No merge, deployment or activation authorization from this task.**

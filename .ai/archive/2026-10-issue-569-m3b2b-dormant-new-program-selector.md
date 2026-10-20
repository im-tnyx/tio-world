# #569 M3B2B1 — Dormant Move to New Program selection UI

**Status:** **Validated / archived 2026-10-20.** [PR #600](https://github.com/im-tnyx/tio-world/pull/600) squash-merged as `main@55ef926e9ed1be1300061f065b8f3458019410d7` (verified `gh pr list --state merged` on 2026-10-20). Parent [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569) stays OPEN. Production Move stays OFF. The historical status line is not the current handoff.
**Historical status:** **Status:** In review, [PR #600](https://github.com/im-tnyx/tio-world/pull/600) Ready for Review and unmerged. Latest source/test HEAD `b7029caf8570c8f52c5bfc4f1e70ac35c68fbe36` [Flutter CI #39104577882](https://github.com/im-tnyx/tio-world/actions/runs/39104577882) **SUCCESS 7/7**; both inline review threads resolved. This later task-document update requires separate exact-head checks. No live Move activation.
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
**PR / tracker:** [PR #600](https://github.com/im-tnyx/tio-world/pull/600) Open / Ready for Review, GitHub #569, Linear TNYX-81, TNYX-267, #568 separately gated.
**Current implementation state:** Source/test `055d887e` implemented the dormant selector; Codex P2 post-dispatch auth switch refresh issue in PR #600 fixed at source/test `b31ccc28` for both New and existing Program paths; three new focused widget regressions added. App remains unwired and Supabase RPC grant is still revoked.
**Validation completed at SHA:** Latest source/test HEAD `b7029caf8570c8f52c5bfc4f1e70ac35c68fbe36`: [Flutter CI #39104577882](https://github.com/im-tnyx/tio-world/actions/runs/39104577882) COMPLETED SUCCESS, 5/5 Flutter/Dart jobs and 2/2 attribution checks (7/7). Earlier source `055d887e` [CI #39101518706](https://github.com/im-tnyx/tio-world/actions/runs/39101518706) was also 7/7. No local/device execution claimed.
**Validation remaining:** Verify exact checks on this subsequent governance-only commit, independent GitHub APPROVED review or documented review-policy disposition, explicit owner `Go merge` authorization; local Windows and physical device QA not run. Hosted activation separately gated.
**Current blocker:** Actual protected Create+Move client gateway/app shell and Supabase release remain separate.
**Open review finding IDs:** Zero unresolved. Codex auth-switch P2 [#4305930495](https://github.com/im-tnyx/tio-world/pull/600#discussion_r4305930495) fixed at `b31ccc28` with three regressions; manual edited-name/final-cancel coverage P3 [#4306020215](https://github.com/im-tnyx/tio-world/pull/600#discussion_r4306020215) fixed in test-only `b7029caf`, with confirmation of unchanged owner-visible writes. Both threads resolved after exact-head CI #39104577882 PASS 7/7. No independent GitHub `APPROVED` review.
**Next exact action:** Validate the new governance-only HEAD CI and review-policy gate, then await explicit owner `Go merge` for dormant #600. Only after safe merge begin one separately owned Flutter atomic adapter slice; do not connect the app callback, deploy or grant EXECUTE here.

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
- [x] Edited name `Cardio Focus` reaches atomic callback without standalone Program insert; final Cancel for `Evening Training` performs zero writes (test-only `b7029caf`), exact-head CI #39104577882 7/7 PASS; P3 resolved.
- [ ] New handoff-only HEAD CI, independent review or verified policy disposition, explicit owner `Go merge`.
- [ ] App-shell auth/operation mutex, protected atomic backend adapter, deployed migration, client grants, #568 and physical QA as separate slices.

## 6. Quality Review
**Remote CI:** latest source/test `b7029caf` [Flutter CI #39104577882](https://github.com/im-tnyx/tio-world/actions/runs/39104577882) completed SUCCESS: five Flutter/Dart checks + two attribution checks = 7/7. Diff since `c2242028` is strictly one changed widget-test file validating edited names, no phantom Program writes, and cancellation. No local Windows `git status`, local `flutter`, or device QA performed.
**Manual scoped code audit:** six intended paths; no SQL or apps/app diff, optional callback not provided by production; existing destination route unchanged, name-only editor never calls `ProgramRepository.create`. Codex P2 identified session change after dispatched atomic callback, where a committed mutation erroneously returned false and blocked caller refresh. `b31ccc28` changes both atomic and existing Move post-dispatch return paths and UNKNOWN/error handling to preserve `attempted` while suppressing old-session success/unknown messages, with three widget regression tests. Exact P2 fix **Flutter CI #39102545276 completed SUCCESS 7/7 at `8e1b961d`**, including the changed app-workout tests. No original-user success feedback is shown after auth changes. Future activation still requires shared process-lifetime concurrency/unknown gates and app-shell owner/session guards. Independent approval not claimed.

## 7. Final Handoff
**Changed paths:** `programs_controller.dart`, `programs_surface.dart`, `routine_move_flow.dart`, `routine_move_flow_test.dart`, this handoff and `.ai/tasks/README.md`.
**Actual behavior:** New Program path is opt-in via an injected future atomic callback, not callable from the app. It prompts the existing editor for an editable name without writing, then confirms Create & Move. Existing destination flow remains.
**Known limits:** In-flight and uncertain-result cross-operation protection must be implemented in real atomic client adapter; #568 default My Program, app-shell wiring, Supabase rollout and device QA still pending.
**Final status:** READY FOR OWNER REVIEW / MERGE GATE; latest source+test CI 7/7, zero unresolved threads and no new code-level P1/P2 on this bounded slice. Independent APPROVED review and explicit `Go merge` are not supplied by CI. **No merge, deployment, grant or Move activation authorized.**

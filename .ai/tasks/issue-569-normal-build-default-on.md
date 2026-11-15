# GitHub #569 — Move Routine normal-build default ON

**Status:** Implementation complete; PR handoff pending
**Primary owner:** Codex
**Affected platforms:** Flutter app shell, app tests, developer documentation, CI gate, task handoff

## Owner Approval and Scope Boundary

**Trigger:** Existing owner-approved #569 implementation follow-up; no new product-visible UI/UX or database shape change.
**Approval status:** Approved
**Approval evidence:** User's explicit task instruction: enable the existing Move Routine for normal development builds, with public release builds default OFF.
**Approved product/UI/data-shape boundaries:** Change only the existing `routineMoveReleaseEnabledProvider` default; preserve `TIO_MOVE_ROUTINE_RELEASE` override and the existing Move, Select Program, New Program, Save & Move, and real Undo flows.
**Explicit non-changes:** No UI redesign, navigation/layout/token change, duplicated flag, runtime toggle, Supabase RPC/RLS/grant/schema/migration change, hosted write, deployment, distribution, public-release default enablement, merge, or unrelated behavior change.

## Active Handoff

**Planning owner:** GitHub #569 / Linear TNYX-81
**Implementation owner:** Codex
**Previous agent:** Not applicable
**Last commit agent:** Codex
**Last commit SHA:** `38510b0265f944b2eddd85ac0bb35e6c4574ca1c`
**Review owner:** GitHub PR reviewers; independent security review remains tracked separately by #675
**Implementation ownership state:** Implementation complete; awaiting exact-head CI/review
**Ownership transition:** Not applicable
**Repository state last verified:** `tnyx/issue-569-normal-build-default-on` based on `1c59273c55d04049914d70db7e52aaf740b3444f`
**Branch:** `tnyx/issue-569-normal-build-default-on`
**HEAD SHA:** `38510b0265f944b2eddd85ac0bb35e6c4574ca1c` (implementation commit; base `1c59273c55d04049914d70db7e52aaf740b3444f`).
**Observed working-tree state:** Focused implementation committed on the task branch; no unrelated pre-existing work was present.
**Observed uncommitted/dirty files:** None after the implementation commit; PR handoff/task-state follow-up remains to be committed.
**PR / tracker:** #569 OPEN; #675 OPEN. Linear TNYX-81 is Backlog and blocked by TNYX-78 and TNYX-80. PR #662 was independently approved and merged; PRs #676 (R4) and #677 (R5) are merged. No open Move Routine PR existed before this slice; this slice's PR is pending creation.
**Current implementation state:** The existing provider now defaults ON when `!kReleaseMode` and OFF in release; explicit `TIO_MOVE_ROUTINE_RELEASE=true|false` overrides remain. Move, Save & Move, and Undo behavior are unchanged.
**Relevant execution surface:** `apps/app/lib/app/composition/workout_providers.dart`; `apps/app/test/app/routine_move_release_gate_test.dart`; `apps/app/test/app/network_providers_test.dart`; `apps/app/test/app/workout_exercises_route_test.dart`; `.github/workflows/flutter-ci.yml`; `docs/development/DEVELOPMENT_SETUP.md`; `docs/screens/routine-library.md`; `docs/data/SUPABASE_STRATEGY.md`.
**Validation completed at SHA:** `38510b0265f944b2eddd85ac0bb35e6c4574ca1c`. App and workout package `flutter analyze` passed. Provider true/false/default gate tests, app network/provider tests (20), route tests (94), Move/Undo flow (52), destination controller (13), refresh signal (3), repository (113), and delete-attempt gate (7) passed. Android debug, profile, and release APK builds passed without a define. Dart format check passed on the changed provider/gate files; the larger route/network tests retain their pre-existing formatting with only task-related hunks. `git diff --check` passed after all code/document edits.
**Validation remaining:** Push, create the focused PR, then verify exact-head CI/reviews. No hosted write or device QA is part of this slice.
**Current blocker:** No source blocker. Public release remains gated by the unrun hosted HTTP/JWT matrix, independent #675 security review, same-attempt Undo evidence, and Android/iOS acceptance/owner sign-off.
**Open review finding IDs:** None for this slice yet; pre-existing #675 review debt remains open.
**Next exact action:** Commit this SHA/handoff update, push the focused branch, create its PR, record the exact head, and wait for exact-head CI/review without merging.

## 1. Discovery

### User Outcome

Routine Move should be available in normal Flutter debug/profile builds without an extra `--dart-define`. Public release builds must continue to default OFF. The existing explicit `TIO_MOVE_ROUTINE_RELEASE=true|false` override must continue working.

### Success Criteria

1. Default debug/profile build evaluates the existing provider ON; default release build evaluates OFF.
2. Explicit `TIO_MOVE_ROUTINE_RELEASE=false` disables Move in development builds; explicit `true` still opts an internal release candidate in.
3. Existing action sheet, destination selector, New Program / Save & Move, mutation guards, and Undo remain unchanged.
4. Tests assert default, explicit OFF, explicit ON and a normal development route exposing the existing Move action.
5. Canonical docs and task handoff describe current source accurately and retain outstanding security/QA release blockers.
6. No Supabase/database/runtime API changes and no public release activation.

### Scope

- Flutter compile-time provider default and affected tests.
- CI coverage for explicit OFF while retaining explicit ON coverage.
- Current Move release/build-mode documentation and #569 handoff reconciliation.

### Non-Goals

- Implementing Move, Save & Move, or Undo behavior; these already exist.
- Changing any screen geometry, navigation, option visibility rules beyond the approved build gate, or server authorization.
- Hosted RPC/HTTP QA writes, Supabase changes, app distribution, public release default ON, merge, or deployment.

## 2. Codebase Exploration

### Verified Evidence

- The active repository is `G:\projects\Tio-World`; starting worktree was clean at `main@1c59273c55d04049914d70db7e52aaf740b3444f`.
- `routineMoveReleaseEnabledProvider` currently reads `bool.fromEnvironment('TIO_MOVE_ROUTINE_RELEASE', defaultValue: false)`. `kDebugMode` is already imported for other providers.
- `shell_route.dart` consumes the provider to gate the existing Move action and dispatch; the Move implementation and actual Undo are already present.
- `routine_move_release_gate_test.dart` currently asserts ordinary builds OFF and CI has an explicit `true` opt-in test. Several route/network tests also encode default OFF and require explicit test gating updates.
- Existing runbook, Routine screen doc and task index contain stale default-OFF statements. Current hosted metadata (read-only, 2026-11-15) records all three Move RPCs as authenticated-callable; Security Advisor still reports authenticated-callable SECURITY DEFINER warnings. These findings are not cleared by this source change.
- GitHub #569 is OPEN; #675 is OPEN. Linear TNYX-81 is Backlog, blocked by TNYX-78/TNYX-80. Owner-reported partial hosted QA is recorded on #569; N2–N6 and exact same-attempt five-second Undo evidence remain outstanding / not independently replayed.

### Architecture Decision

Use `!kReleaseMode` as the existing environment default for the existing boolean `String.fromEnvironment`/`bool.fromEnvironment` gate. Flutter debug and profile modes therefore default ON; release defaults OFF. A supplied `TIO_MOVE_ROUTINE_RELEASE` value continues to override the mode default. Keep all gate ownership in the existing app-shell provider.

### Validation Plan

- Run the provider test in normal debug, explicit OFF, and explicit ON configurations.
- Run the default-on route regression and relevant Move/Undo feature tests.
- Run `flutter analyze` and app tests with the supplied Flutter SDK at `G:\dev\flutter-sdk`.
- Build Android debug/profile/release without the define when toolchain permits; inspect source/test results for mode-specific behavior.
- Run `git diff --check` and review the final diff for forbidden UI/DB changes.
- Verify exact PR-head CI and review; do not merge.

## 3. Final Handoff

To be completed after validation and PR review state are observed. Public release remains separately gated by #675 and uncompleted owner/guest HTTP, device, and owner go/no-go evidence.

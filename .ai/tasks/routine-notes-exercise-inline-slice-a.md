# Routine Notes — Exercise inline UI Slice A

**Status:** In progress
**Primary owner:** Current implementation session
**Affected platforms:** Flutter phone Create/Edit Routine; Supabase contract consumed read-only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice / product-visible UI
**Approval status:** Approved
**Approval evidence:** Owner instruction `Tio-world — Exercise Notes Inline UI Implementation` received 2026-11-02, with the attached screenshot as the visual and interaction reference.
**Approved product/UI/data-shape boundaries:** Add Exercise-scoped Notes inline inside the existing Create/Edit Routine Exercise card, directly below Rest/Note actions and above the Set table. Use `RoutineNoteScope.exercise(ExerciseRef)`, the existing `RoutineNotesRepository`, existing authenticated provider/session guards, existing five-note and 500-character limits, and existing delete/mutation-safety behavior. Owner clarification received 2026-11-02 supersedes the earlier inline `Save Note`/`Cancel` decision: the Note field is a temporary inline draft and has no separate Save or Cancel buttons; the owner expects the surrounding Routine save flow to commit it. The current slice does not invent a new aggregate Notes payload or write separately on keystroke. The owner also approves tapping the left pin icon or right-swiping a saved Note to change Note type, left-swiping a saved Note to reveal Delete, and showing `Delete Note` in the type sheet before the existing confirmation. Type transfer uses the existing atomic repository contract; `Pinned Routine` is enabled only when an existing Routine identity is available (Edit), while Create remains Exercise-scoped until the Routine has a durable identity.
**Explicit non-changes:** No sheet/dialog/navigation page for creating or editing the Note, no autosave or per-keystroke write, no copy/share, new repository/model/table/migration/RLS/grant, hosted deployment, Rest Timer redesign, Set/table redesign, WorkoutSession/history/post behavior, or physical-device acceptance claim. The separate Routine Notes block is not part of the approved Exercise Notes surface and is no longer mounted on Routine Detail. The type chooser is limited to the explicitly approved type-change action and does not become a general Note editor.

## Active Handoff

**Planning owner:** Current implementation session
**Implementation owner:** Current implementation session
**Review owner:** Independent GitHub review (`im-tio`) when PR exists
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-11-05
**Branch:** `codex/routine-notes-exercise-inline-slice-a`
**HEAD SHA at last source/CI audit:** `57f446890538baa7c83a1559541e3c644fd71d0e` plus the current uncommitted remediation diff
**Observed working-tree state:** Two confirmed review fixes are implemented locally and not yet pushed; generated Android registrant remains unrelated and excluded
**Observed uncommitted/dirty files:** Flutter tooling reports a metadata-only `apps/app/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` change; it is not part of this slice
**PR / tracker:** GitHub PR #725 (`https://github.com/im-tnyx/tio-world/pull/725`) linked to existing GitHub #716 and Linear `TNYX-81`; independent review requested from `im-tio`; no separate child issue available in the current Linear workspace limit
**Current implementation state:** Shared Create/Edit composer mounts inline Exercise Notes and captures drafts for the surrounding Routine Save/Update. After the Routine mutation is confirmed, the existing `RoutineNotesRepository` receives canonical Exercise/Routine commands through a stable-ID bridge; quota/validation rejection leaves the draft editable or discardable, while unknown/unavailable outcomes keep the exit safety block. Failed Edit updates restore captured draft text after the saved-state rebuild; no new data source or backend contract is introduced. The current remediation constrains only the Rest control inside the existing Rest/Note row at compact width, and emits the existing owner/login-cycle-scoped refresh signal after a confirmed parent Routine write when Notes later fail, including Edit unknown reconciliation.
**Relevant execution surface:** `apps/features/workout/lib/src/presentation/library/routines/routine_composer_screen.dart`
**Validation completed locally:** Elevated Flutter SDK access allowed the current focused Notes/parent-refresh suite (`73/73`), Create/Edit Routine suite (`55/55`), full `apps/features/workout` suite (`1136/1136`), `apps/features/workout` analysis, and `apps/app` analysis to pass. The new bridge regression covers an unknown mutation that remains an exit barrier after a later validation failure. Dart formatting completed; `git diff --check` completed with only the existing generated-file, CRLF and fsmonitor warnings. The initial sandbox timeout was a machine-local SDK cache permission limitation, not a repository or Git source failure; no SDK reinstall or global Git configuration change was performed.
**Validation remaining:** Fresh independent approval, exact-head GitHub CI after this push, and independently reproduced physical Android/iOS QA
**Current blocker:** No local source/toolchain blocker remains after running Flutter with the required SDK cache access. The owner-provided physical-device evidence is recorded separately and is not an independent reproduction. Hosted Notes objects remain outside this PR and are not activated.
**Open review finding IDs:** At PR HEAD `57f446890538baa7c83a1559541e3c644fd71d0e`, two current threads remain open: Cursor parent-refresh finding `4441608549` in `shell_route.dart`, and `im-tio` compact-layout finding in `exercise_notes_inline.dart`. The local remediation addresses both; all older threads remain resolved/outdated. The standalone Routine Detail Notes refresh finding is superseded by the owner-approved removal of the separate Routine Notes section. Fresh independent approval remains open.
**Next exact action:** Commit and push only the scoped remediation files, then recheck exact-head CI, both review threads, Main Protection and `im-tio` approval. Keep PR #725 unmerged.

## 1. Discovery

### User Outcome

Users can create and view private Exercise Notes inline while building or editing a Routine, without leaving the Exercise/Set context or opening a modal editor.

### Success Criteria

- The existing `Note` action focuses an inline multiline field and opens the normal keyboard.
- The inline Note field is hidden on first render and appears only after the user taps `Note`.
- Draft text survives rebuilds and keyboard inset changes.
- The draft has no inline Save/Cancel controls; parent Routine-save persistence is a remaining bridge gate.
- Exercise Notes use canonical `ExerciseRef` identity and existing owner/session guards.
- Read/create/delete, quota, validation and uncertain-save states are covered.
- Existing Rest Timer, Set table, Add Set and Routine-level Notes behavior remain unchanged.

### Scope

Shared `RoutineComposerExerciseCard`, its feature-owned controller/widget support, Create/Edit wiring, focused tests and this handoff.

### Non-Goals

Editing existing note bodies, copy/share, pinned presentation redesign, schema/deployment, device QA and unrelated Routine UI. Type transfer is included only for the explicitly approved pin-icon and right-swipe interaction.

## 2. Codebase Exploration

### Verified Evidence

- `RoutineNotesRepository` already exposes `read/create/update/transfer/delete`; the current Routine aggregate save command does not carry a Notes payload.
- `RoutineNotesController` already owns 5-note quota, 500-rune normalization, owner/scope validation, session checks and unknown create reconciliation; it will be generalized to accept an existing `RoutineNoteScope` without changing Routine behavior.
- `RoutineComposerExerciseCard` is the shared Create/Edit Exercise header, Rest control, Set header/table and Add Set surface.
- `routineNotesRepositoryProvider` is authenticated and login-cycle bound in `apps/app`.
- `TioCard` and `showTioConfirmationBottomSheet` are reused for saved-note actions. Core `TioInput.multiline` is intentionally not used for the draft because its current contract is outlined with a 52dp minimum; the feature uses a governed borderless `TextField` with Core tokens for this screenshot-specific inline row.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Inline commit behavior | Superseded | Owner’s latest direction removes inline `Save Note`/`Cancel`; the draft remains temporary until a parent Routine-save bridge is approved and implemented. | Owner follow-up |
| Existing note edit behavior | Deferred | Body editing remains out of scope; type transfer is separately approved by the 2026-11-02 follow-up. | Owner scope |
| Note type change | Made | Left pin icon opens the existing option-sheet pattern; transfer calls the existing atomic `transfer` contract. Create cannot target a Routine before Save. | Owner follow-up |
| Delete gesture | Made | Saved Notes use the existing swipe-to-reveal destructive action pattern plus the established confirmation; no mutation on partial drag. | Owner follow-up |
| Create/Edit Routine persistence timing | Implemented bridge | The parent waits for confirmed Routine Save/Update, then commits captured drafts through the existing Notes repository. A failed or unknown Note result keeps the top-level Save/Update retry state; the bridge does not claim atomicity that the existing contracts cannot provide. | Existing data contract / owner direction |

## 4. Architecture Design

### Chosen Approach

Generalize the existing `RoutineNotesController` from fixed Routine scope to injected `RoutineNoteScope`, retain the existing Routine constructor behavior, and mount a feature-owned inline `ExerciseNotesInline` widget in the shared composer card.

### Ownership and Data Flow

```text
RoutineComposerExerciseCard
  -> ExerciseNotesInline
  -> RoutineNotesController(scope: RoutineNoteScope.exercise(ExerciseRef))
  -> RoutineNotesRepository
  -> SupabaseRoutineNotesRepository
  -> existing Notes RPC/read contract
```

### Alternative Rejected

The existing `TioEditorSheet` was rejected for Exercise Notes because the approved interaction is inline and must keep the Exercise/Set context visible.

### Failure and Accessibility States

Loading, empty, quota-disabled, invalid body, save failure, unknown save notice/reconciliation, stale-session fail-closed behavior, delete confirmation, semantic labels, keyboard-visible scroll and compact/large-text layouts.

## 5. Implementation Plan

- [x] Generalize the existing controller to accept Routine or Exercise scope.
- [x] Add the inline Exercise Notes widget with temporary draft input, type chooser, type-sheet Delete action and swipe-to-reveal delete.
- [x] Wire authenticated repository and session callback through app Create/Edit routes.
- [x] Preserve the existing Rest/Set/Add Set geometry and behavior in the shared composer.
- [x] Add focused tests and run local validation; Flutter tests require elevated SDK-root access on this machine, but pass there.
- [x] Resolve the PR CI findings without backend/schema changes: governed motion token and invalid-owner fail-closed compatibility.
- [x] Resolve the current local review/CI regressions without backend/schema changes: unknown-save refresh, callback-identity preservation, transfer-failure note preservation, scope-aware deletion copy, ready-state quota messaging, and compact-width action-row overflow.
- [x] Remove the Notes-specific `Try again` recovery action from Routine Detail; a failed Notes read is now silent because Notes follow the surrounding Routine save contract.
- [x] Remove the separate Routine Notes section and its Detail-route repository/session wiring; Detail now remains exercise-only.
- [x] Retain the former optional Detail Notes constructor inputs as compatibility-only fields so a stale running caller cannot crash after the UI removal; they do not mount or fetch Notes.
- [x] Add the parent Routine-save bridge that commits temporary drafts only after the Routine mutation is confirmed, with stable Note/mutation IDs and unknown-outcome reconciliation.
- [x] Share one Notes controller per canonical Exercise scope within each Create/Edit composer so duplicate Exercise cards observe the same persisted state.
- [x] Preserve editable/discardable drafts after definite quota/validation rejection and restore captured drafts after a failed Edit Update remount; keep exit blocked only for unknown/unavailable/unauthorized Note outcomes.
- [x] Keep undispatched quota/definite-failure commands retryable with their stable IDs, reconcile unknown outcomes before dispatched-state blocking, lock parent Save/Update and exit while Notes are in flight, keep confirmed partial successes read-only, canonicalize restored/new draft IDs, and clear captured drafts on Edit reload.
- [x] Keep unknown commands immutable until reconciliation, reconcile pending unknown commands even after the visible draft is removed, render Routine-scoped Notes in the same inline Exercise/Set surface, refresh the destination scope after transfer, and bound the Rest action for compact rows.

## 6. Quality Review

### Validation Run

**Current remediation verification (2026-11-05):**

```text
PASS: `flutter test --reporter expanded --no-pub test/presentation/edit_routine_page_test.dart test/presentation/routine_detail_page_test.dart test/presentation/routine_notes_save_bridge_test.dart test/presentation/routine_move_refresh_signal_test.dart` in `apps/features/workout` — 73 tests passed
PASS: `flutter test --reporter compact --no-pub` in `apps/features/workout` — 1,140 tests passed
PASS: `flutter test --reporter expanded --no-pub test/app/workout_exercises_route_test.dart` in `apps/app` — 89 tests passed
PASS: `flutter test --reporter compact --no-pub` in `apps/app` — 470 tests passed, 1 skipped test
PASS: `flutter test --reporter compact --no-pub test/theme/final_enforcement_visual_ownership_test.dart test/theme/final_enforcement_primitive_liveness_test.dart` in `apps/core` — 2 tests passed
PASS: `flutter analyze --no-pub` in `apps/features/workout` — no issues
PASS: `flutter analyze --no-pub` in `apps/app` — no issues
PASS: `git diff --check` on the working tree
BLOCKED/NOT RUN: exact-head GitHub CI after the new commit, fresh independent review, and independently reproduced physical-device QA
```

```text
PASS: `G:\dev\flutter-sdk\bin\flutter.bat --suppress-analytics test --no-pub test/presentation/exercise_notes_inline_test.dart test/presentation/routine_notes_controller_test.dart test/presentation/routine_composer_screen_test.dart --reporter compact` in `apps/features/workout`
PASS: `G:\dev\flutter-sdk\bin\flutter.bat --suppress-analytics test --no-pub test/presentation/edit_routine_page_test.dart --plain-name "320dp dark Edit table retains Previous and range inputs" --reporter expanded` in `apps/features/workout`
PASS: `G:\dev\flutter-sdk\bin\flutter.bat --suppress-analytics test --no-pub test/presentation/edit_routine_page_test.dart --reporter compact` in `apps/features/workout`
PASS: `G:\dev\flutter-sdk\bin\flutter.bat --suppress-analytics analyze --no-pub` in `apps/features/workout`
PASS: `G:\dev\flutter-sdk\bin\flutter.bat --suppress-analytics analyze --no-pub` in `apps/app`
PASS: `G:\dev\flutter-sdk\bin\flutter.bat --suppress-analytics test --no-pub test/theme/final_enforcement_visual_ownership_test.dart --reporter compact` in `apps/core`
PASS: `G:\dev\flutter-sdk\bin\dart.bat format apps/features/workout/lib/src/presentation/library/routines/exercise_notes_inline.dart apps/features/workout/lib/src/presentation/library/routines/routine_notes_controller.dart apps/features/workout/lib/src/presentation/library/routines/routine_composer_screen.dart` — formatting completed
PASS: `git -c core.fsmonitor=false diff --check`
PASS: Dart analyzer for `apps/features/workout` exits 0; the repository has no analyzer diagnostics after the bridge/registry changes.
PASS: `G:\dev\flutter-sdk\bin\flutter.bat test --no-pub test/presentation/routine_notes_save_bridge_test.dart test/presentation/exercise_notes_inline_test.dart` — 21 tests passed, including quota-rejected draft discard and remount restoration.
PASS: `G:\dev\flutter-sdk\bin\flutter.bat test --no-pub test/presentation/create_routine_page_test.dart test/presentation/edit_routine_page_test.dart` — 54 tests passed.
PASS: `G:\dev\flutter-sdk\bin\flutter.bat test --no-pub --reporter compact` in `apps/features/workout` — 1,130 tests passed.
PASS: `G:\dev\flutter-sdk\bin\flutter.bat test --no-pub test/presentation/routine_notes_save_bridge_test.dart` — 8 bridge tests passed after the retry/reconciliation remediation.
PASS: `G:\dev\flutter-sdk\bin\flutter.bat test --no-pub test/presentation/routine_notes_save_bridge_test.dart test/presentation/exercise_notes_inline_test.dart test/presentation/create_routine_page_test.dart test/presentation/edit_routine_page_test.dart` — 76 focused tests passed.
PASS: `G:\dev\flutter-sdk\bin\flutter.bat test --no-pub test/presentation/routine_notes_save_bridge_test.dart test/presentation/exercise_notes_inline_test.dart test/presentation/create_routine_page_test.dart test/presentation/edit_routine_page_test.dart` — 79 focused tests passed after the latest review remediation.
PASS: `G:\dev\flutter-sdk\bin\flutter.bat test --no-pub` in `apps/features/workout` — 1,135 tests passed.
PASS: `G:\dev\flutter-sdk\bin\flutter.bat analyze --no-pub` in `apps/features/workout` after the latest review remediation.
PASS: `G:\dev\flutter-sdk\bin\flutter.bat analyze --no-pub` in `apps/app` after the latest source follow-up.
PASS: `G:\dev\flutter-sdk\bin\flutter.bat test --reporter compact test/presentation/routine_notes_save_bridge_test.dart test/presentation/exercise_notes_inline_test.dart test/presentation/program_detail_page_test.dart test/presentation/routine_notes_controller_test.dart test/presentation/routine_notes_section_test.dart test/presentation/routine_move_refresh_signal_test.dart` in `apps/features/workout` — 73 tests passed.
PASS: `G:\dev\flutter-sdk\bin\flutter.bat test --reporter compact test/presentation/create_routine_page_test.dart test/presentation/edit_routine_page_test.dart` in `apps/features/workout` — 55 tests passed.
PASS: `G:\dev\flutter-sdk\bin\flutter.bat test --reporter compact` in `apps/features/workout` — 1,136 tests passed after `e87c419b`.
PASS: `G:\dev\flutter-sdk\bin\flutter.bat analyze` in `apps/features/workout` and `apps/app` after `e87c419b`.
PASS: GitHub PR #725 exact-head CI for `c6eeca608d1224ca80aba79a45c0ea751a2dc300` — Analyze/test aggregate, Flutter matrix, docs hygiene, and attribution checks passed; Cursor agents were skipped.
PASS: GitHub PR #725 exact-head CI for `a7803fb59ce681e8cc3bb684e3f6ece29fa6cde6` — Analyze/test aggregate, Flutter matrix, docs hygiene, and attribution checks passed; Cursor agents were skipped.
PASS: GitHub PR #725 exact-head CI for `1b40c1813812f4b0b89e360b555a3d7155c5d9bb` — Analyze/test aggregate, Flutter matrix, docs hygiene, and attribution checks passed; Cursor agents were skipped.
NOT RUN: physical Android/iOS keyboard and gesture QA, hosted Notes deployment, and independent review approval
```

### Review Provenance

**Review source / link:** GitHub PR #725 (`https://github.com/im-tnyx/tio-world/pull/725`)
**Reviewer / relation to implementer:** Independent reviewer requested: `im-tio`
**Diff or commit SHA actually reviewed:** Latest submitted independent `im-tio` review was on PR HEAD `a245b01169bba621adf61916f76cc4753ff4da37` and withheld approval. A fresh `im-tio` review request is pending for exact HEAD `1b40c1813812f4b0b89e360b555a3d7155c5d9bb`.
**Review result and finding dispositions:** Review comments were reconciled against current source. The standalone Routine Detail Notes-section comment is superseded by the owner correction and remains intentionally removed. The current unknown-exit and parent-refresh findings are fixed in `e87c419b`; refreshed independent review remains pending.
**Independent review?** Requested / pending
**Limitations and unmet required gates:** Hosted Notes deployment remains intentionally blocked; physical Android/iOS QA and fresh independent approval remain open. GitHub's main branch protection endpoint currently returns `404 Branch not protected`, so required protection rules are not independently verifiable from that endpoint.

## 7. Final Handoff

### Changed Files

- `apps/features/workout/lib/src/presentation/library/routines/exercise_notes_inline.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_notes_section.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_detail_page.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_notes_controller.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_move_refresh_signal.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_composer_screen.dart`
- `apps/features/workout/lib/src/presentation/library/routines/create_routine_page.dart`
- `apps/features/workout/lib/src/presentation/library/routines/edit_routine_page.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_notes_save_bridge.dart`
- `apps/app/lib/app/composition/workout_providers.dart`
- `apps/app/lib/app/routing/shell/shell_route.dart`
- `apps/features/workout/test/presentation/exercise_notes_inline_test.dart`
- `apps/features/workout/test/presentation/routine_notes_save_bridge_test.dart`
- `apps/features/workout/test/presentation/routine_notes_section_test.dart`
- `apps/features/workout/test/presentation/routine_notes_controller_test.dart`
- `apps/features/workout/lib/src/presentation/library/library.dart`

### Actual Behavior

- `Note` remains beside Rest and focuses the compact borderless inline Exercise Note input; no inline Save/Cancel controls or editor sheet are used.
- `Rest` and `Note` remain in one governed action row; `Rest` stays left and `Note` sits immediately to its right with equal governed control height, without moving to the screen edge or wrapping below Rest at the approved compact width.
- `Note` uses the same local `Material`/`InkWell` capsule geometry as the existing Rest action—surface, radius, padding, icon size, typography and height—while retaining Note-specific semantics and focus behavior.
- The first Exercise render shows only the action row and Set surface; the compact borderless text field appears only after `Note` is tapped and remains a local draft until the parent-save bridge exists.
- The Create/Edit inline Exercise Notes surface does not render a Notes-specific loading, error, or `Retry` state; the surrounding Routine save flow owns persistence feedback.
- In `debug` builds only, when Notes persistence is unavailable, the Note field can be previewed and typed into without issuing a repository/Supabase write; release builds remain fail-closed.
- Draft text is held by the stateful inline widget while keyboard/rebuild events occur; `Scrollable.ensureVisible` requests the focused field into view.
- Saved Notes render inline with existing Core input/card/theme patterns, five-note quota, 500-character validation, owner/session guards and delete confirmation.
- Tapping the pin icon opens the approved `Notes type` sheet. A saved Note can also open it through right swipe; Create mode exposes only Exercise scope, while Edit mode can transfer to the current Routine through the existing atomic repository contract.
- The saved-note `Notes type` sheet now includes a red `Delete Note` action; selecting it closes the sheet and opens the existing confirmation before any delete mutation.
- The draft `Notes type` sheet also includes the red `Delete Note` action; selecting it clears the temporary draft and closes the inline field without a repository write.
- The draft field’s left icon follows the selected scope: `push_pin_outlined` for Exercise and `assignment_outlined` for Routine.
- Tapping `Note` again adds another independent inline draft field; saved Notes plus drafts are capped at five active slots.
- The inline UI cap is four active slots (saved Notes plus drafts); the existing backend five-note safety contract is unchanged.
- The type-sheet option layout keeps each icon and title on the first line, with the explanatory subtitle on a full-width line below, matching the owner screenshot.
- Left swipe reveals the red `Delete` action; delete occurs only after tapping the revealed action and confirming.
- The existing Routine Notes controller/repository contract remains available for the approved Create/Edit flow, but Routine Detail no longer mounts a separate Routine Notes surface.
- Routine Detail no longer renders a Notes-specific failure message or `Try again` action; Notes do not create a separate recovery flow.
- Routine Detail no longer mounts the separate `Routine Notes` section; Notes remain available only in the approved Exercise/ Routine-save composition path.
- `RoutineDetailPage` retains deprecated optional Notes constructor inputs only for runtime/source compatibility; they are ignored and cannot render a separate Notes surface.
- Create/Edit now treats inline Note drafts as part of the top-level Routine Save/Update flow: Routine persistence is confirmed first, then the existing Notes repository is called with canonical scope and stable IDs. If Notes persistence fails or is unknown, the Routine result is not presented as “Routine + Notes saved”; the same top-level Save/Update remains available for retry while the draft is retained. Definite quota/validation rejection leaves the user free to correct or remove the draft and exit; unknown/unavailable/unauthorized outcomes keep the safety block.
- A previously unknown Notes mutation remains an exit-safety barrier even when a later save attempt returns validation/quota failure; the bridge exposes this state until exact-command reconciliation confirms it.
- After the parent Routine mutation is confirmed, the shell emits an owner/login-cycle-scoped read invalidation immediately. This refreshes the still-mounted Program/Routine parent even if the later Notes bridge rejects definitively, without claiming Notes success or atomicity.
- If Edit rebuilding replaces the Exercise cards after a failed Note commit, captured draft text/type/identity is restored into the inline fields before the next retry.
- Duplicate Exercise entries with the same canonical `ExerciseRef` share one page-scoped Notes controller, while their temporary text drafts remain card-local.

### Notes Flow

1. **Create/Edit Routine:** The Exercise row shows only `Rest` and `Note` in one aligned action row. The note field is hidden initially.
2. **Tap `Note`:** A compact, borderless, multiline draft field appears inline below the actions and above Sets. The keyboard opens and the draft remains local while the widget rebuilds.
3. **Draft actions:** There are no inline `Save Note`, `Cancel`, `Retry`, or Notes-specific error controls. The pin icon opens the approved type sheet; tapping `Note` again adds another temporary draft, capped at four UI slots.
4. **Routine save:** The top-level Save/Update first confirms the existing Routine mutation. Only then does the parent-save bridge commit the captured drafts through `RoutineNotesRepository`; it does not autosave or write on every keystroke. A failed or unknown Notes result leaves the draft and the same top-level Save/Update retry path visible.
5. **Routine Detail:** No separate `Routine Notes` heading, section, repository read, or retry action is mounted. The Detail constructor keeps deprecated optional Notes inputs only to avoid runtime constructor incompatibility with stale callers; they are ignored.
6. **Scope and safety:** Existing Exercise Notes use canonical `ExerciseRef`, owner/session guards, existing quota/length contracts, and existing swipe/type/delete behavior where the saved-note path is available. No Supabase schema, migration, grant, RLS, or hosted configuration changed.

### Known Limitations

The bridge is intentionally sequential rather than falsely atomic because the existing Routine and Notes repositories expose separate contracts. Hosted Notes migrations are not applied; this does not authorize production activation. Existing body edit/copy/share behavior remains out of scope. Physical Android/iOS gesture and keyboard QA remains pending. Fresh independent approval remains pending; all review threads and exact-head CI for `1b40c181` are reconciled.

### Final Status

`REVIEW`

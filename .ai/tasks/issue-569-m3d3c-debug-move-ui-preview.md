# #569 M3D3C — Explicit debug-only Move Routine UI preview

**Status:** In progress
**Primary owner:** One cross-package implementation owner for Workout feature presentation and phone app-shell composition/tests
**Affected platforms:** Flutter Android/iOS debug-only opt-in; all release/profile builds unchanged

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice and bounded dev-only visible interaction.
**Approval status:** Approved by owner on 2026-10-18: after prior explicit discussion of an internal Move UI preview on physical dev app, owner requested "next slice audit ke baad ... agent.md ... workflow.md ... start".
**Approved outcome:** On a debug build built with an explicit build-time opt-in, signed-in owner of an existing persisted Routine may inspect the current shared action sheet, top-row `+ New Program`, owner-scoped eligible existing destinations, editable generated Program name, and confirmation dialogs. After confirmation the preview reports **no data saved**. This allows phone UI visual/interaction QA before protected backend capability release.
**Explicit non-changes:** Never make an ordinary release/profile app show Move from this preview flag; never grant hosted Move EXECUTE, deploy an atomic Create+Move RPC, change Supabase shape/RLS, create a new persisted Program, perform Move/create writes, or fabricate a successful move. No UI redesign, unrelated feature, iOS/watch work, or merge without separate owner instruction.

## Active Handoff

- **Planning and Implementation owner:** One bounded Workout feature + apps/app composition owner.
- **Review owner:** Independent/Codex pending after exact-head CI.
- **Implementation ownership state:** Active; predecessor #606 merged and no open PRs at planning audit.
- **Repository state last verified:** Protected `main@e08d547b6cfe3c99096029f2df9c5196b6aad006` (squash merge #606), GitHub API confirms no open PRs. Post-merge Flutter CI at planning start still in progress.
- **Branch:** `tnyx/issue-569-m3d3c-debug-move-ui-preview`, created from exact `main` head. Working tree cannot be observed via remote GitHub connector; no local Windows reset, stash, prune or sync.
- **Trackers:** GitHub #569 open, related #568 open, Linear TNYX-81 broad Backlog and blocked by TNYX-78/80.
- **Validation:** Not run on new slice yet; do not infer CI from prior PR.
- **Next exact action:** Implement preview-only gate, enforce write interception in Workout flow, add both branch-specific and real app-router tests, open Draft PR, validate and hand off.

## Owner physical-device UI acceptance amendments — 2026-10-18

**Approval trigger:** Owner visually inspected the actual opted-in debug PR #607 branch on their phone and explicitly requested bounded UX corrections in the same Move destination selector. No separately scoped product work.
**Requested changes:**
- On selecting Routine's `Move Routine`, open the destination bottom sheet immediately, not after waiting for network inspection. Show an interim loading state *within* the same existing Core editor sheet, then display only verified owner-scoped destinations; preserve auth/login-cycle cancellation, retry/unknown safety, and all write gates.
- Destination sheet title becomes **Select Program**; the Routine three-dot action remains **Move Routine** and final confirmations retain their descriptive existing copy.
- Existing destinations are separated from New Program by one horizontal divider, replacing the instructional phrase. The divider is absent when no eligible existing destination is present.
- New Program row has **one plus**: leading plus icon and text `New Program` (no plus embedded in the label). Do not add Program icons or modify other screens.
**Source evidence:** `RoutineMoveFlow.run` awaits `RoutineMoveDestinationController.inspect` (readOwned header + ProgramRepository.list) *before* calling `showTioEditorSheet`, explaining the observed hand-off gap under network latency. `TioEditorSheet` shared geometry is not the owner of this asynchronous pause; do not globally alter Core sheet or route insets. Old label was `+ New Program` *and* `Icons.add_rounded`.
**Non-goals:** No Product/Program icon redesign; no RPC grant, real write activation, preview-guard weakening or other sheet-layout change.
**Additional validation:** Delayed inspect and list loading must show the title/sheet promptly and zero destination choices until both reads verify; auth cancellation and no stale destination; selected destinations/new-only divider rules; existing preview zero-write and app two-surface tests; exact branch CI.
**Implementation state:** Added to current Draft PR #607 scope, validation pending.

## Seven-phase workflow

### 1. Discovery
The user needs to visually test the actual Move Routine bottom sheet on their dev phone, including source-only `+ New Program` and existing destination options, without releasing unsupported database mutations. Existing Routine and Program data remains real owner-scoped read-only.

### 2. Codebase Exploration
Read root `AGENTS.md`, nested `apps/features/AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, task template, Core theme/visual rules, current Workout Move flow/controller/repos/tests, `apps/app` provider and shell wiring, canonical module ownership and Routine docs, GitHub #569/#568 and Linear TNYX-81. PR #606 merged with test-only Riverpod override; production `routineMoveReleaseEnabledProvider` is hard `false`. Hosted `move_user_workout_routine` grant revoked and atomic Create+Move absent. Do not mistake those gates for a safe actual write.

### 3. Clarification / decisions
No new schema, network capability, feature design, or app-store release. Opt-in must require **both** Flutter `kDebugMode` and compile-time `--dart-define=TIO_MOVE_ROUTINE_UI_PREVIEW=true`; unset defaults `false`. Tests can explicitly override provider, but tests cannot establish APK installation or QA. Debug-only preview must not piggyback on `routineMoveReleaseEnabledProvider`.

### 4. Architecture Design
- App shell owns compiled debug-preview capability and live Auth/bootstrap/SDK checks, existing nullable action callback, and passes `previewOnly` to feature-owned `RoutineMoveFlow`.
- Workout owns UI flow, uses existing editor sheets and destination controller (owner-safe read), but preview branches intercept both existing Move and atomic Create+Move **before any write dispatcher**. Return `false` to never indicate success/refresh; present explicit no-change feedback. Cancels remain zero write.
- Existing actual-write release gate remains hard OFF independently; preview cannot be enabled in release/profile binaries even with injected dart-define. No new fake local Program list or mock data in deployed app.
- Rejected alternatives: set existing release flag true, enable Supabase grants, create fake successful records, create a duplicate modal UI, use environment flag alone in profile/release.

### 5. Implementation Plan
- [ ] Scoped debug/define provider, no production release flag changes.
- [ ] Feature Move flow preview intercept both writes at final confirmation, no false success.
- [ ] Feature widget tests for existing target and New Program confirmation: 0 Move/atomic/create, false refresh, visible no-save feedback; cancel and owner-session safety.
- [ ] Real app-router widget regression for both Program Detail and expanded Library debug preview, with auth/SDK owner and zero gateway writes.
- [ ] CI, exact changed-file/ancestry diff audit, Codex review, handoff.

### 6. Quality Review
**Validation run:** Not yet on this branch.
**Security/privacy:** All Program lists remain read-only authenticated owner scoped. Preview is not an authorization bypass for database writes.
**Visual safety:** Reuse existing Core Modal and confirmation; no changed fixed spacing/geometry.
**Open findings:** Await validation/review.

### 7. Final Handoff
**Status:** IN PROGRESS. No build/device QA, RPC, grant, feature activation or merge claimed.

## 2026-10-18 Owner device QA feedback / contained visual revision

**Evidence:** Owner manually ran the opted-in debug branch on a physical device and confirmed the Move destination sheet appears. Owner reported a pause between the Routine 3-dot action sheet and the destination sheet; second sheet title lacked destination clarity; double plus before New Program; verbose text between New Program and saved Programs. Owner explicitly deferred any leading icon for existing Program rows.

**Approved UI-only adjustments, no additional backend scope:**
- Keep the first Routine action label **Move Routine** unchanged, but call the second sheet **Select Program**.
- Retain the existing leading add icon and change row text from `+ New Program` to **New Program** (one plus).
- Replace `Select an existing destination Program` with a Core/Material `Divider`, shown **only** when there is both a New Program row and one or more eligible existing destinations. With only the current saved Program, the selector shows only New Program and no divider.
- Start the app-guarded Move destination inspection on the user Move tap while the first sheet starts dismissing instead of waiting for the sheet's reverse animation to finish. The Move app callback must still re-check Auth/bootstrap/SDK current-owner and login-cycle; never dispatch twice. Actual async server read latency is not under the UI's control. No premature success or backend write.
- No existing Program row icon in this slice. Preserve Core TioEditorSheet, spacing roles, and both Program Detail and expanded Library routes.

**Implementation checkpoint:** Source and widget regressions committed on the existing Draft PR #607 branch. Feature test asserts header/one leading icon/conditional divider and one immediate Move callback before completion of the reverse animation. App-router preview tests keep zero-write and both-surface checks. **CI and independent review of the latest commit not yet verified; no device retest of new refinements claimed.** Release gate remains default OFF; dev preview remains opt-in/debug-only.

## 2026-10-18 Owner screenshot feedback — Move preview confirmation pill

**Owner-visible scope approval:** Owner supplied screenshot as a feedback reference and specified a **floating pill**, right-aligned **Undo**, and **5-second display**, with existing Delete Routine feedback as a visual pattern. This is a bounded UI refinement of the debug-only preview, not approval to activate a real Move or add a reversal API.

**Decision:** The preview confirmation shows a Delete-pattern Material floating Snackbar pill with `StadiumBorder`, an informational icon, short **“Preview only · No changes”** copy and right `Undo` `SnackBarAction`, duration **5 seconds**. During debug preview there is **no persisted mutation**, so tapping Undo **only dismisses that preview pill**; it must never fake restoration, send a Move/Create+Move RPC, or claim a successfully undone Move. Genuine post-commit Undo requires a separately reviewed, authenticated, revision-safe server reversal and list refresh, outside this slice. Non-preview error feedback remains unchanged. Real confirmed Move currently has no Undo action.

**Validation:** Changed only Workout presentation flow and feature/app widget regressions, plus task/PR handoff. Both existing-destination and atomic New-Program preview paths still assert zero writes; feature widget tests additionally assert 5-second floating shape, Undo and dismissal. Source/test HEAD `5db5e4d0` Flutter CI #39152699480 was IN PROGRESS at this checkpoint; do not mark as passed until exact SHA completes. Owner verified the earlier preview on a physical device, not this latest pill.

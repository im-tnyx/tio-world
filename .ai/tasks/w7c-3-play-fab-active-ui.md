# Feature Task: W7C-3 Play FAB and Active Workout UI-only entry

**Status:** In progress — PR / CI evidence pending
**Primary owner:** ChatGPT GitHub implementation agent, bounded UI slice
**Affected platforms:** Flutter Android and iOS phone

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product-visible UI/navigation slice
**Approval status:** Approved
**Approval evidence:** Owner request on 2026-11-08 supplying Active Workout UI references and directing a Nutrition-style Play FAB on Workout Home, opening the Active Workout screen. Finish details screen is later; current work is UI-only. Follow-up screenshot review explicitly rejects Retry/Back controls on Log Workout regardless of database availability, requires the Add Exercise UI to remain visible, and approves a Discard Workout action directly below Add Exercise. The latest owner-approved empty-start reference requires the Duration/Volume/Sets strip, a centred `Get started` empty state, full-width Add Exercise, a Settings/Discard Workout pair, and a disabled `Finish` action at the top-bar end using exact `TioSize.dp34` visual height.
**Approved boundaries:** Play FAB (icon play), existing /workout/active presentation, real session/snapshot rendering, editable performed-set inputs using existing Core/Routine numeric conventions and responsive routine-row geometry, meaningful empty/preview UI, no Retry/Back recovery controls, existing-controller discard confirmation for real active sessions, and the existing Routine `ExercisesPage` picker for a local, in-memory blank-preview exercise draft. The selected-preview exercise is a full-width, card-free routine-style section (not a second card design and not a `1 sets` label); its centered set grid uses the Routine badge/boxed-input geometry. Its local check requires both KG and Reps and updates only preview stats/completion visual.
**Explicit non-changes:** No ad-hoc session creation, no fake Routine/Exercise/IDs, no hosted Supabase, schema/RLS/RPC, no new protected mutation, no persistence of the blank-preview exercise draft or its local check state, no Finish summary screen, no Wear/watch, no extra feature settings, no broad design system redesign.

## Active Handoff

**Planning owner:** ChatGPT read-only audit
**Implementation owner:** ChatGPT GitHub implementation agent
**Review owner:** Independent reviewer to be requested under current branch protection
**Implementation ownership state:** Active until reviewed handoff
**Ownership transition:** Consolidated the temporary Play FAB/UI work into the existing W7C-3 branch without rewriting original commits. The consolidation merge has original W7C-3 HEAD `0f32b91` and W7C-2 merged main `c76c81d` as parents, and selects the already-audited combined UI tree. Original implementation history remains reachable. PR #740 is canonical; duplicate PR #741 is superseded/closed.
**Repository state last verified:** 2026-11-08; branch is based on pushed handoff commit `7f75b7cff2f848c318dd561feffe81d07b914374`, with the owner-approved blank-workout UI corrections locally validated and awaiting one focused commit. Remote main remains `c76c81d79395bb7f242e321a9fdde1d1fc08e270`.
**Branch:** feat/w7c-3-active-workout-execution-ui
**Observed working-tree state:** GitHub API only; owner local Windows worktree not accessible
**PR / tracker:** GitHub PR #740 / GitHub #739 / Linear TNYX-84
**Relevant execution surface:** apps/features/workout, apps/app routing, .ai task handoff
**Validation completed at SHA:** `79e8bbc5ecac55b0d39804e2db5dfdd67d4d5a43` passed the original exact-head Flutter CI (`42502870451`) and prior typed-set regression suite. The current uncommitted owner-approved UI update passed local `flutter analyze` in `apps/features/workout` (0 issues), `apps/features/workout/test/presentation/active_workout_page_test.dart` (23 PASS), `workout_rpe_sheet_test.dart` (6 PASS), `save_workout_page_test.dart` (12 PASS), `workout_duration_picker_sheet_test.dart` (3 PASS), and full module suite (1,317 PASS). Architecture modularized into reusable presentation widgets (`workout_exercise_card.dart`, `workout_set_input_row.dart`, `workout_set_type_sheet.dart`, `workout_rpe_sheet.dart`, `workout_activity_type_sheet.dart`, `workout_duration_picker_sheet.dart`) and screens (`save_workout_page.dart`, `gym_selection_page.dart`) without screen bloat. Finish button navigates to Save Workout screen with editable duration stat opening `WorkoutDurationPickerSheet` (reusing `TioWheelPickerTokens` with 3-drum wheels for Hours, Minutes, Seconds), photo/video card, borderless/clean description notes, canonical `TioDateTimeWheelPicker` date/time sheet with explicit bounded height (`TioWheelPickerTokens.viewportHeight`), capped at current local time without future date/time scrolling (matching Nutrition meal log and Progress weight log), grouped Activity Type sheet, and reused `WorkoutRpeSheet` for overall workout RPE ("How hard was this workout?"). Gym location supports search/selection via `GymSelectionPage` (with home gym and popular gyms like Sky Fitness) or clearing to None. Title does not auto-fill with exercise name (defaults to routine title or user input) and renders without box. Visibility option removed per user direction.
**Validation remaining:** Re-run Home/controller/app-routing suites on this final diff, `git diff --check`, push this validated change, exact-head hosted CI, independent review, and real-device visual QA. The compact light/dark evidence is a local widget test, not device acceptance.
**Current blocker:** The deployed database reported `PGRST205` for missing `public.user_workout_sessions`; this UI slice intentionally does not deploy/migrate Supabase or fabricate session persistence. GitHub also requires review (`REVIEW_REQUIRED` / `BLOCKED`); no automatic merge. The typed-set root cause was render-time KG/Reps parsing captured by the completion-button callback before an input edit's scheduled rebuild, so it could submit a previous prescribed rep value.
**Next exact action:** Reconcile remote immediately before the focused commit/push, publish to existing PR #740, then refresh exact-head CI and obtain independent review; do not merge automatically.

## 1. Discovery

User wants a familiar Nutrition-style floating Play action on Workout Home. The Play action opens the reference-aligned Log Workout screen even before workout-start persistence is approved. Real active sessions still restore using the canonical controller.

## 2. Codebase Exploration

- Read root AGENTS.md, apps/features/AGENTS.md, Core theme README, architecture ownership, .ai/FEATURE_DEVELOPMENT, GitHub push/PR templates, #739 and TNYX-84.
- `MealDiaryLogAction` is a one-off Nutrition FAB composed from governed Core colors, shadows, 56dp sizing; reuse its theme/layout contract but do not import Nutrition into Workout.
- `RoutineSetInputRow` edits a Routine SetPrescription; cannot represent a performed set truth. Reuse Core boxedNumber and existing RoutineSetInputLimits for actual-set entry.
- `ActiveWorkoutPage` already consumes auth-bound controller and `WorkoutSessionSnapshot` under W7C-2; W7C-3 exploration adds stats/set UI.
- `WorkoutHomePage` is a date surface, app shell owns navigation and `/workout/active` already has no bottom bar/auth gating.

## 3. Clarification

| Decision | Status | Rationale |
| --- | --- | --- |
| Play opens Active Workout route directly (not separate Start page) | Owner-approved | Explicit current direction supersedes the earlier two-option #739 proposal for this UI slice |
| No data / no session | UI preview only | Preserves protected startup contract; zero persisted workout, zero fake exercises |
| Finish summary/new route | Deferred | Explicit owner instruction: separate screen later. Existing resumed-session completion path is not redesigned here |
| Add Set / Add Exercise persistence | Deferred | No approved snapshot mutation |
| Actual set input | UI wired to existing logSet only when a real session exists | Never silently uses prescription as performed truth |

## 4. Architecture Design

Workout Home action -> app-owned navigation to `/workout/active?preview=1` -> feature-owned ActiveWorkoutPage. With no real session, show an in-memory UI preview; with a real session, render controller-backed state. No new session engine or local-only production data. Numeric input from `TioInput.boxedNumber`, feature-owned validation, existing `controller.logSet` mutation only for actual user-entered values.

**Rejected alternative:** Import Nutrition FAB into Workout or directly use RoutineSetInputRow; both breach feature/data ownership. Also rejected automatically launching a fake/empty server session.

**Failure/accessibility:** Existing auth invalidation and reconciliation states stay authoritative; FAB has label/tooltip; preview Add Exercise is enabled while Finish/Settings/Discard remain visibly disabled without a session; pending actions protected; month expansion hides FAB.

### Gym Location Architecture (Google Places API + Supabase Proxy)
- **Status:** Implemented & Verified with automated Deno and Flutter test suites.
- **Client GPS:** Uses `geolocator` on Flutter client to query device coordinates (`latitude`, `longitude`) with standard OS permissions (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` on Android; `NSLocationWhenInUseUsageDescription` on iOS). Timeout guards ensure testing stability without hanging.
- **Server-Side Proxy:** Per `AGENTS.md` ("Client apps may use only client-safe keys and APIs; never expose server keys/secrets in client apps"), requests route through Supabase Edge Function `/functions/v1/nearby-gyms`.
- **Google Places API:** Edge function securely reads `GOOGLE_PLACES_API_KEY` from environment secrets and queries Google Places API (New) (`places:searchNearby` with `includedTypes: ["gym", "fitness_center"]` around coordinates or `places:searchText` for queries), calculating distance with Haversine formula and sorting results.
- **Privacy & Fallbacks:** `Home gym` (private location) is pinned in suggestions; `None` fallback when cleared. Fallback popular gyms provided when location or network is unavailable.
- **Tests:** 6/6 Deno unit tests in `supabase/functions/nearby-gyms/index_test.ts`; 12/12 widget tests in `save_workout_page_test.dart`; 1,317/1,317 tests in `apps/features/workout`.

## 5. Implementation Plan

- [x] Workout Play FAB with Nutrition-style governed appearance.
- [x] Workout Home callback and app-owned route wiring.
- [x] Truthful no-session preview on Play entry, without mutating data.
- [x] Preserve W7C-3 screenshot-inspired stats/set UI and accept entered actual set values.
- [x] Focused widget tests authored.
- [ ] Exact-head CI, independent review, compact-width device validation.

## 6. Quality Review

**Validation:** Exact-head GitHub CI not yet verified; source/ancestry checks only. GitHub API work cannot run the owner's local Flutter SDK or device tests in this environment. Do not claim test pass before CI.

**Review provenance:** Pending independent GitHub review. ChatGPT implementation/self-inspection is not independent approval.

## 7. Final Handoff

**Status:** REVIEW — source-fix exact-head CI passed; independent review, owner authorization, and real-device QA remain separate gates.

No changes to Supabase or protected server contracts. No merge or deployment authorization.

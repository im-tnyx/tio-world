# Feature Task: W7C-3 Play FAB and Active Workout UI-only entry

**Status:** In progress — PR / CI evidence pending
**Primary owner:** ChatGPT GitHub implementation agent, bounded UI slice
**Affected platforms:** Flutter Android and iOS phone

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product-visible UI/navigation slice
**Approval status:** Approved
**Approval evidence:** Owner request on 2026-11-08 supplying three Active Workout UI reference screenshots and directing a Nutrition-style Play FAB on Workout Home, opening the Active Workout screen. Finish details screen is later; current work is UI-only.
**Approved boundaries:** Play FAB (icon play), existing /workout/active presentation, real session/snapshot rendering, editable performed-set inputs using existing Core/Routine numeric conventions, meaningful empty/preview UI, focused tests.
**Explicit non-changes:** No ad-hoc session creation, no fake Routine/Exercise/IDs, no hosted Supabase, schema/RLS/RPC, no new protected mutation, no Finish summary screen, no Wear/watch, no extra feature settings, no broad design system redesign.

## Active Handoff

**Planning owner:** ChatGPT read-only audit
**Implementation owner:** ChatGPT GitHub implementation agent
**Review owner:** Independent reviewer to be requested under current branch protection
**Implementation ownership state:** Active until reviewed handoff
**Ownership transition:** Consolidated the temporary Play FAB/UI work into the existing W7C-3 branch without rewriting original commits. The consolidation merge has original W7C-3 HEAD `0f32b91` and W7C-2 merged main `c76c81d` as parents, and selects the already-audited combined UI tree. Original implementation history remains reachable. PR #740 is canonical; duplicate PR #741 is superseded/closed.
**Repository state last verified:** 2026-11-08; code-fix commit `79e8bbc5ecac55b0d39804e2db5dfdd67d4d5a43` is pushed to the aligned W7C-3 branch; remote main remains `c76c81d79395bb7f242e321a9fdde1d1fc08e270`.
**Branch:** feat/w7c-3-active-workout-execution-ui
**Observed working-tree state:** GitHub API only; owner local Windows worktree not accessible
**PR / tracker:** GitHub PR #740 / GitHub #739 / Linear TNYX-84
**Relevant execution surface:** apps/features/workout, apps/app routing, .ai task handoff
**Validation completed at SHA:** `79e8bbc5ecac55b0d39804e2db5dfdd67d4d5a43` passed local `G:\dev\flutter-sdk\bin\flutter.bat analyze` in `apps/features/workout`; focused Active Workout/Home/controller suites (95 tests PASS); affected app provider/Workout-route suites (97 tests PASS); and `git diff --check`. Hosted exact-head Flutter CI run `42502870451` passed every shard and aggregate, while Docs Hygiene and Attribution also passed. The Active Workout widget suite covers immediate typed `12 KG × 6 Reps` logging, blank immediate drafts, restored actual values, controller-backed state update, and a `320×640` dark scrollable execution view without exceptions. Prior CI at `d3d68fa998b6479ddef0fadabd81e00fe855cb39` remains historical failure evidence only.
**Validation remaining:** Independent review, owner-approved merge, and real-device visual QA. The compact light/dark evidence is a local widget test, not device acceptance.
**Current blocker:** GitHub requires review (`REVIEW_REQUIRED` / `BLOCKED`); no automatic merge. The typed-set root cause was render-time KG/Reps parsing captured by the completion-button callback before an input edit's scheduled rebuild, so it could submit a previous prescribed rep value.
**Next exact action:** Refresh CI on this handoff-only commit, then obtain independent review and explicit owner merge authorization; do not merge automatically.

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

Workout Home action -> app-owned navigation to `/workout/active?preview=1` -> feature-owned ActiveWorkoutPage. With no real session, show read-only UI preview; with a real session, render controller-backed state. No new session engine or local-only production data. Numeric input from `TioInput.boxedNumber`, feature-owned validation, existing `controller.logSet` mutation only for actual user-entered values.

**Rejected alternative:** Import Nutrition FAB into Workout or directly use RoutineSetInputRow; both breach feature/data ownership. Also rejected automatically launching a fake/empty server session.

**Failure/accessibility:** Existing auth invalidation and reconciliation states stay authoritative; FAB has label/tooltip; no-session actions visibly disabled; pending actions protected; month expansion hides FAB.

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

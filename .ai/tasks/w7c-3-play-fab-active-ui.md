# Feature Task: W7C-3 Active Workout execution and completion

**Status:** In progress — correctness, duration-wheel, persistence, and exact-head merge gates pending
**Primary owner:** Current local Codex implementation owner, continuing PR #740 on the existing branch
**Affected platforms:** Flutter Android and iOS phone

## Owner Approval and Scope Boundary

**Trigger:** Owner-approved W7C-3 execution and completion slice, expanded by the request on 2026-11-09.
**Approval status:** Approved for the requested runtime correctness work, the single 0–300-minute duration wheel, and real-save as the product goal. The earlier UI-only boundary in this brief and GitHub #739 is superseded for this active task. This does **not** approve a new Supabase table/column shape, hosted migration, Edge Function deployment, or billable infrastructure.
**Approved boundaries:** Preserve all owner-approved Active Workout and Save Workout visuals. Keep the Workout Home Play FAB and current route; fix current-session reconciliation, execution measurement capture, stable exercise identity, gym provider ownership/search/permission/fallback correctness, and Save truthfulness. Replace only the duration picker with one bounded 0–300-minute wheel, preserving canonical session timer precision and never mutating stored duration on open/cancel. Complete real Start/Set/Pause/Resume/Finish/Save/Restore/History behavior through already approved repository/backend contracts when available. Update focused tests and task/tracker evidence.
**Explicit non-changes:** No UI redesign beyond the duration wheel. No fabricated IDs/data, local-only production session or fake save. No new schema/RPC/table/column shape implementation or hosted migration/deployment without exact owner approval. No Google Places deployment, new billable infrastructure, branch creation, force push, or automatic merge. No wearable or unrelated roadmap work.

**Approved Save-title addendum (2026-11-09):** Workout Title is optional. At Save submission, trim surrounding whitespace from a nonblank custom title; otherwise derive `Morning Workout` (05:00–11:59), `Afternoon Workout` (12:00–16:59), `Evening Workout` (17:00–20:59), or `Night Workout` (21:00–04:59) from the selected local workout Date & Time. Never block Save for an empty title. Preserve the resolved value through canonical persistence, retry, restore, and history/detail reads. Keep the existing UI unchanged. The checked-in W7 session RPC/repository currently has no title argument/field and does not persist the editable Save Date & Time. Exact owner approval for a minimal owner-scoped schema/RPC extension is pending; do not implement a UI-only title or claim it was saved.

## Active Handoff

**Planning owner:** Current Codex agent (preflight and scope reconciliation complete)
**Implementation owner:** Current local Codex agent
**Review owner:** Independent GitHub reviewer (`i-the` currently requested); must review the latest eligible HEAD
**Implementation ownership state:** Taken over from the prior ChatGPT GitHub implementation agent after repository/tracker reconstruction; no concurrent implementation owner is known.
**Ownership transfer record:** Previous Implementation Owner `ChatGPT GitHub implementation agent` → Receiving Implementation Owner `current local Codex implementation agent`. Verified clean worktree, branch `feat/w7c-3-active-workout-execution-ui`, local/live PR HEAD `0c23e8fd5acafc09a5b97fb720c6f833fc9c602a`, local/cached `origin/main` and PR base `c76c81d79395bb7f242e321a9fdde1d1fc08e270`, no stashes listed. Direct `git fetch` is unavailable (`.git/FETCH_HEAD` permission denied; GitHub DNS unavailable); connected GitHub PR metadata confirms exact head/base. Scope continues the owner-approved W7C-3 task and does not grant the separate Supabase shape/deployment gate.
**Ownership transition:** Consolidated the temporary Play FAB/UI work into the existing W7C-3 branch without rewriting original commits. The consolidation merge has original W7C-3 HEAD `0f32b91` and W7C-2 merged main `c76c81d` as parents, and selects the already-audited combined UI tree. Original implementation history remains reachable. PR #740 is canonical; duplicate PR #741 is superseded/closed.
**Repository state last verified:** 2026-11-09; working tree contains the 16 modified paths listed by `git status --short --branch`, local HEAD remains `0c23e8fd5acafc09a5b97fb720c6f833fc9c602a`, and no stash was listed. The PR-connected live head/base still match local HEAD and cached `origin/main`; remote fetch remains unavailable. Changes are uncommitted and unpublished.
**Branch:** feat/w7c-3-active-workout-execution-ui
**Observed working-tree state:** Local repository verified; clean before this task's edits; no stashes listed. Current source/task changes remain uncommitted.
**PR / tracker:** GitHub PR #740 / GitHub #739 / Linear TNYX-84
**Relevant execution surface:** apps/features/workout, apps/app routing, .ai task handoff
**Validation completed at SHA:** Historical CI/test evidence at `79e8bbc5ecac55b0d39804e2db5dfdd67d4d5a43` is not current-head evidence. In this session `dart format` completed on the 12 changed Dart paths. Running `flutter.bat` stalled; direct Flutter tool invocation failed because its configured Git executable could not start (`G:\dev\git\cmd\git.EXE`: directory name invalid). Deno test execution was attempted but stopped before tests because JSR `@std/assert` could not be fetched (network unavailable). No current Dart tests/analyze, Deno tests, app build, visual comparison, hosted persistence test, or exact-head CI has passed in this session.
**Current blockers:** Correct Supabase project `oykupyiitspujzpwwvuj` has migrations only through `20261031142025`; live metadata has no `public.user_workout_sessions`, `public.user_workout_performed_sets`, W7 session RPCs, or deployed `nearby-gyms`. Repo migration `20261106073920_user_workout_sessions.sql` and W7B contracts exist but are not hosted. The source completion RPC persists notes but not title or editable selected Save Date & Time; Save currently disables those unsupported fields for real sessions. No title-only or fabricated success path is permitted. The exact auto-title persistence schema/RPC proposal is awaiting owner decision. Google Places security source changes do not include deployment or verified quotas/billing/rate limiting. PR #740 still needs exact-head CI and independent approval; do not resolve review threads until source fixes are validated.
**Tracker update:** Linear TNYX-84 received the verified title requirement, current source/hosted contract gap, and validation limitations in a comment. The attempted GitHub #739 comment was rejected by automatic review because the available comment action was PR-scoped and could target PR #739 instead of Issue #739; no alternate GitHub write was attempted. PR #740 and all review/merge gates remain unchanged.
**Next exact action:** Obtain an owner decision on the proposed title/date-time persistence contract; continue source-only review fixes and focused validation for the already-authorized non-schema slices. Refresh GitHub/Linear state at the eligible HEAD, request independent re-review, then preserve the no-automatic-merge gate.

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
| No data / no session | Entry preview only; Finish must not claim or simulate persistence | Preserves protected startup contract; zero persisted workout, zero fake exercises |
| Finish/save of a real supported session | Use existing session repository completion; Save reports success only after canonical completion confirmation | Current source contract supports notes, but not title or edited Save metadata; title/date-time schema proposal awaits owner approval |
| Add Set / Add Exercise persistence | Existing repository operations only; report unsupported operations as blocked | No approved snapshot amendment operation for ad-hoc/empty sessions |
| Actual set input | UI wired to existing logSet only when a real session exists | Never silently uses prescription as performed truth |

## 4. Architecture Design

Workout Home action -> app-owned navigation to `/workout/active?preview=1` -> feature-owned ActiveWorkoutPage. With no real session, show an in-memory UI preview; with a real session, render controller-backed state. No new session engine or local-only production data. Numeric input from `TioInput.boxedNumber`, feature-owned validation, existing `controller.logSet` mutation only for actual user-entered values.

**Rejected alternative:** Import Nutrition FAB into Workout or directly use RoutineSetInputRow; both breach feature/data ownership. Also rejected automatically launching a fake/empty server session.

**Failure/accessibility:** Existing auth invalidation and reconciliation states stay authoritative; FAB has label/tooltip; preview Add Exercise is enabled while Finish/Settings/Discard remain visibly disabled without a session; pending actions protected; month expansion hides FAB.

### Gym Location Architecture (Google Places API + Supabase Proxy)
- **Status:** Source changes under review; current tests were not run successfully in this session. Hosted `nearby-gyms` is absent and is not deployed.
- **Client GPS:** Uses `geolocator` on Flutter client to query device coordinates (`latitude`, `longitude`) with standard OS permissions (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` on Android; `NSLocationWhenInUseUsageDescription` on iOS). Timeout guards ensure testing stability without hanging.
- **Server-Side Proxy:** Per `AGENTS.md` ("Client apps may use only client-safe keys and APIs; never expose server keys/secrets in client apps"), requests route through Supabase Edge Function `/functions/v1/nearby-gyms`.
- **Google Places API:** Edge function securely reads `GOOGLE_PLACES_API_KEY` from environment secrets and queries Google Places API (New) (`places:searchNearby` with `includedTypes: ["gym", "fitness_center"]` around coordinates or `places:searchText` for queries), calculating distance with Haversine formula and sorting results.
- **Privacy & Fallbacks:** No hardcoded nearby results or distance values; failed/denied location leaves no fabricated nearby list. Google quota, billing, and abuse-rate controls still require owner/security disposition before deployment.
- **Tests:** Deno attempted, blocked at JSR dependency fetch; Flutter tests/analyze blocked by local Flutter tool Git launch failure. No test passes are claimed for this working tree.

## 5. Implementation Plan

- [x] Workout Play FAB with Nutrition-style governed appearance.
- [x] Workout Home callback and app-owned route wiring.
- [x] Truthful no-session preview on Play entry, without mutating data.
- [x] Preserve W7C-3 screenshot-inspired stats/set UI and accept entered actual set values.
- [x] Focused widget regression tests authored for duration, save truthfulness, execution measurements, and preview completion.
- [ ] Focused regression tests completed and run on this working tree, including title boundaries/persistence after backend approval.
- [ ] Exact-head CI, independent review, compact-width device validation.

## 6. Quality Review

**Validation:** Current source changes are uncommitted. Flutter/Deno test attempts are blocked as recorded above. Exact-head GitHub CI is not available for these local changes. Device comparison, hosted persistence, and independent review are pending.

**Review-thread source dispositions (not independently validated; leave all threads unresolved):**

1. P1 false preview Save success — removed preview Save navigation; Finish explains the draft is not saved and retains it. Regression test authored, not run.
2. P1 session hidden by empty preview during reconciliation — reconciliation state remains authoritative even when entry requested preview. Test not run.
3. P1 duration/distance ignored — set row parses and validates those values, passes `durationSeconds`/`distanceMeters` to `logSet`, and renders restored values. Focused test authored, not run.
4. P1 repository constructed in GymSelectionPage — construction moved to app composition/provider and injected through `GymLocationRepository`. Test not run.
5. P2 Save metadata dropped — notes pass to canonical completion; unsupported title/date/time/duration/gym/activity/RPE edits are disabled for real-session Save. Auto-title and selected timestamp persistence await owner-approved contract. Success requires canonical completion confirmation. Tests authored, not run.
6. P2 exercise removal index corruption — preview maps and set-keyed maps are reindexed on removal. Dedicated identity regression test not yet authored/run.
7. P2 gym response race — initial and typed searches share request-generation guards for result/loading updates. Race regression test not yet authored/run.
8. P2 permission prompt timeout — timeout removed from `requestPermission`; position acquisition remains bounded. Permission-path test not yet authored/run.
9. P2 Set Type/RPE lost on restore — persisted-session override callbacks are unavailable; immutable snapshot type remains and widget-only overrides are not offered. Restoration test not yet authored/run.
10. P2 fabricated Jaipur proximity — hardcoded gyms/distances removed; denied/network failure returns no fabricated nearby list. Deno tests authored but blocked before execution by unavailable JSR access.

**Nearby-gyms security:** Auth verification, bounded request validation, generic errors, and checked-in `verify_jwt` are present in source. Deno tests did not execute. Persistent rate/abuse limits and Google quota/billing controls remain unverified; hosted function is absent and deployment is blocked.

**Review provenance:** Pending independent GitHub review. ChatGPT implementation/self-inspection is not independent approval.

## 7. Final Handoff

**Status:** BLOCKED — source slice is in progress; required tests could not run, real-save title/date-time contract approval is pending, and exact-head CI/re-review are unavailable until a published eligible HEAD exists.

No hosted Supabase schema/RPC changes or deployments were made. Source changes do touch the checked-in Edge Function and `supabase/config.toml`. No merge authorization was given.

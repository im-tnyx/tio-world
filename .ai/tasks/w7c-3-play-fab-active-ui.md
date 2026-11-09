# Feature Task: W7C-3 Active Workout execution and completion

**Status:** In progress — exact Save metadata contract is proposed; separate schema approval, pending review fixes, and merge gates remain
**Primary owner:** Current Codex implementation owner, continuing PR #740 on the existing branch
**Affected platforms:** Flutter Android and iOS phone

## Owner Approval and Scope Boundary

**Trigger:** Owner-approved W7C-3 execution and completion slice, expanded by the request on 2026-11-09.
**Approval status:** Approved for the requested runtime correctness work, the single 0–300-minute duration wheel, and real-save as the product goal. The earlier UI-only boundary in this brief and GitHub #739 is superseded for this active task. This does **not** approve a new Supabase table/column shape, hosted migration, Edge Function deployment, or billable infrastructure.
**Approved boundaries:** Preserve all owner-approved Active Workout and Save Workout visuals. Keep the Workout Home Play FAB and current route; fix current-session reconciliation, execution measurement capture, stable exercise identity, gym provider ownership/search/permission/fallback correctness, and Save truthfulness. Replace only the duration picker with one bounded 0–300-minute wheel, preserving canonical session timer precision and never mutating stored duration on open/cancel. Complete real Start/Set/Pause/Resume/Finish/Save/Restore/History behavior through already approved repository/backend contracts when available. Update focused tests and task/tracker evidence.
**Explicit non-changes:** No UI redesign beyond the duration wheel. No fabricated IDs/data, local-only production session or fake save. No new schema/RPC/table/column shape implementation or hosted migration/deployment without exact owner approval. No Google Places deployment, new billable infrastructure, branch creation, force push, or automatic merge. No wearable or unrelated roadmap work.

**Approved Save-title addendum (2026-11-09):** Workout Title is optional. At Save submission, trim surrounding whitespace from a nonblank custom title; otherwise derive `Morning Workout` (05:00–11:59), `Afternoon Workout` (12:00–16:59), `Evening Workout` (17:00–20:59), or `Night Workout` (21:00–04:59) from the selected local workout Date & Time. Never block Save for an empty title. Preserve the resolved value through canonical persistence, retry, restore, and history/detail reads. Keep the existing UI unchanged. The checked-in W7 session RPC/repository currently has no title argument/field and does not persist the editable Save Date & Time. Exact owner approval for a minimal owner-scoped schema/RPC extension is pending; do not implement a UI-only title or claim it was saved.

## Live Reconciliation and Save Contract Proposal — 2026-11-09

**Git / PR:** Repository root `G:\projects\Tio-World`; branch `feat/w7c-3-active-workout-execution-ui`; local HEAD and GitHub PR #740 HEAD are `df9a3fa7c06f7e820a600d234b262de4bed1a9fa`. Worktree clean, no stashes. GitHub API confirms `main@c76c81d79395bb7f242e321a9fdde1d1fc08e270`, also the PR base. `git fetch origin --prune` could not update `.git/FETCH_HEAD` (`Permission denied`); GitHub API is the verified remote source. PR #740 remains open and unmerged.

**Review / CI:** Latest GitHub snapshot has 17/17 unresolved review threads, 8 current and 9 outdated; none were resolved in this audit. Independent review remains `CHANGES_REQUESTED`; there is no independent approval on the latest eligible HEAD. All five PR-triggered workflows on `df9a3fa7` succeeded: Docs Hygiene CI, Supabase Functions CI, Flutter CI (analyze and app-workout/nutrition/core-wear tests), Supabase Database CI (migration replay), and Android Native CI (debug APKs). The separate commit-attribution guard also succeeded. Cursor automated review/security checks are neutral because the connected automation reached its usage limit; they are not independent approval. PR requests `i-the` review.

**Linear / Issue:** TNYX-84 is `In Progress`, blocked by TNYX-80 and TNYX-81 and blocks TNYX-85 and TNYX-88. GitHub #739 still has its historical UI-only scope text; current owner direction supersedes that restriction only for real-save product behavior. A new table/column shape and hosted migration still need separate exact approval.

**Supabase deployment evidence:** Connected project verified as `tio-world`, ref `oykupyiitspujzpwwvuj`, `ACTIVE_HEALTHY`, Postgres 17.6.1. Hosted ledger has 81 entries and ends at `20261031142025`; metadata confirms no public `user_workout_sessions`, `user_workout_performed_sets`, or W7 session RPCs. The only checked-in migration later than that ledger is `20261106073920_user_workout_sessions.sql`; W7B-1 source was merged to `main` by PR #734 but is not hosted. Do not skip it, edit the hosted ledger manually, or deploy any migration in this task. The live Security Advisor also reports existing `SECURITY DEFINER` grants; these are not W7 session objects and require separate context before any disposition.

### Audited existing contract

- `WorkoutSession` requires canonical `sessionId`, `programId`, `routineId`, an immutable routine snapshot, `startedAtUtc`, and `localDate`; `PerformedSet` carries performed weight/reps/duration/distance and stable set IDs. The session header has notes and lifecycle timestamps/revision, but no title or selected Save timestamp/timezone.
- `rpc_start_workout_session` validates a real owner-owned Program/Routine and its exact composition. Routine/program IDs and snapshot are mandatory; there is no empty/ad-hoc Start operation. Do not fabricate IDs or treat Play preview as a persisted session.
- The seven existing RPCs enforce `auth.uid()` ownership, revision checks, parent-row locks and idempotent replay. RLS allows owner-only SELECT; direct table DML is revoked. `rpc_complete_workout_session` currently accepts `session_id`, `expected_revision`, `completed_at_utc`, and `notes`; it changes canonical status/timing and increments revision. It does not accept Save title or edited workout Date & Time.
- `SupabaseWorkoutSessionRepository.completeSession` calls that RPC then owner-scoped readback by session ID. This readback can verify a canonical completion, but there is no completed-history list contract yet; W8/TNYX-85 is a downstream Linear blocker. Existing session ID readback can validate an individual completed row.
- `SaveWorkoutPage` currently submits title/date, but `ActiveWorkoutPage` opens it with `notesOnly: true`, which makes title/date controls read-only. Only description maps to persisted `notes`; session duration remains derived from canonical `WorkoutTime` and must not be replaced by the selected history timestamp. Gym, activity type and overall RPE have no W7 session columns/DTO fields and must not be represented as saved.

### Proposed minimum compatible contract — approval required before source/schema implementation

1. Reuse `public.user_workout_sessions`; do not add a second workout or history table. Add nullable `workout_title text`, `workout_at_utc timestamptz`, and `workout_utc_offset_minutes integer` to preserve legacy rows without guessed backfills. Keep `started_at_utc` as the timer origin and `completed_at_utc` as the actual terminal transition. On new completions, update the existing `local_date` from the selected instant plus its saved UTC offset; do not overwrite the timer origin.
2. Add `rpc_complete_workout_session_v2(p_session_id uuid, p_expected_revision integer, p_completed_at_utc timestamptz, p_notes text, p_workout_title text, p_workout_at_utc timestamptz, p_workout_utc_offset_minutes integer) returns public.user_workout_sessions`. Leave the existing RPC/signature intact for older app clients. V2 requires a nonblank bounded resolved title and an offset within ±14 hours, checks `auth.uid()`, locks only the owner-scoped parent row, requires the exact expected revision, validates timestamp ordering, performs the same pause-accounting and terminal transition, and atomically writes title/time/offset/local_date plus completion. Replayed terminal calls return the existing row only when all completion payload fields match; conflicting replay is rejected. Revoke execute from `PUBLIC`/`anon`; grant only `authenticated`; retain the established `SECURITY DEFINER` + empty `search_path` pattern and explicit owner check because direct DML is denied.
3. In Flutter, resolve the custom title with `.trim()` at submit; otherwise derive the fallback from the selected local DateTime hour at submit, never `DateTime.now()` or UTC hour. Persist the selected instant as UTC plus `selectedDate.timeZoneOffset.inMinutes`. A separate IANA timezone ID is **not required** to round-trip this one selected instant: existing `local_date` plus the contemporaneous offset reconstructs its wall-clock date/time across device timezone changes. This follows the existing MealLog contract, which explicitly accepts either a timezone ID or UTC offset. An IANA ID would only be needed for future rules-based conversion of other instants in the original zone, which this Save contract does not perform.
4. Extend `WorkoutSession`, row DTO, repository/gateway and controller with the additive metadata and V2 call. Keep old JSON decode compatible with null fields for pre-existing rows. The Save page may make only title and selected Date & Time editable for real sessions after this contract is approved; preserve existing geometry and keep unsupported Gym/activity/RPE fields read-only. Await a V2 row plus owner-scoped repository readback showing `status=completed` and the resolved title/time before reporting Save success. Keep the exact submission tuple stable for retries; reconcile unknown outcomes with `getSession(sessionId)` before another completion attempt.
5. No new history store: completed-session details are read through the same owner-scoped table/RLS and `getSession`. Add the W8 history listing against this canonical table only in the separate TNYX-85 slice. Legacy completed rows keep null metadata and use a clearly documented legacy title fallback; do not fabricate historical custom titles.

**Migration/deployment order:** Hosted state is at `20261031142025`. After separate deployment approval, first apply the pending merged W7B migration `20261106073920_user_workout_sessions.sql` in order and verify its migration ledger/objects. Only then create a new W7C follow-up migration using the repo's `supabase migration new` workflow (no hand-invented timestamp), apply it after W7B, and verify columns, RPC signature, RLS/grants and security tests. Do not skip or manually insert ledger entries. Deploy compatible app code only after the additive migration is present. Rollback is forward-only: retain nullable columns/data and the old RPC; if V2 has a defect, stop using V2 in the client and ship a corrective migration. Do not drop columns or erase session metadata as rollback.

**Focused validation plan after approval:** SQL matrix for owner vs other owner/anon, grants and RLS, invalid/blank title, out-of-range UTC offset, timestamp/local-date agreement, OCC stale revision, identical and conflicting terminal replay, completion from active/paused, no duplicate timing/revision writes, legacy old-RPC compatibility, and no writes after terminal; W7B concurrency lock-order regression; Flutter fallback hour boundaries/midnight, trimmed custom title, selected past date/time, no current-time/UTC-hour dependency, legacy DTO decoding, V2 params, exact-row readback, unknown-outcome recovery and completed `getSession` reload; history ordering contract tests when TNYX-85 is active. Re-run migration replay/pgTAP, Flutter analyze/tests, Android build, security advisor and exact-head CI. Hosted integration tests remain separately gated and are not replaced by mocks.

**Exact owner decisions still required:** approve or reject the three nullable columns and `rpc_complete_workout_session_v2` contract above, including the persisted UTC-offset semantics; separately authorize ordered hosted W7B+W7C migration rollout. Product direction alone does not grant these shape/deployment approvals.

## Active Handoff

**Planning owner:** Current Codex agent (preflight and scope reconciliation complete)
**Implementation owner:** Current local Codex agent
**Review owner:** Independent GitHub reviewer (`i-the` currently requested); must review the latest eligible HEAD
**Implementation ownership state:** Taken over from the prior ChatGPT GitHub implementation agent after repository/tracker reconstruction; no concurrent implementation owner is known.
**Ownership transfer record:** Previous Implementation Owner `ChatGPT GitHub implementation agent` → Receiving Implementation Owner `current local Codex implementation owner`. At transfer, verified clean worktree, branch `feat/w7c-3-active-workout-execution-ui`, PR HEAD `0c23e8fd5acafc09a5b97fb720c6f833fc9c602a`, base `c76c81d79395bb7f242e321a9fdde1d1fc08e270`, and no stashes. Scope continues the owner-approved W7C-3 task and does not grant the separate Supabase shape/deployment gate.
**Latest ownership transfer record (2026-11-09):** Previous Implementation Owner `prior local Codex session` → Receiving Implementation Owner `current Codex session`. Reconstructed from clean branch `feat/w7c-3-active-workout-execution-ui` at local/PR HEAD `df9a3fa7c06f7e820a600d234b262de4bed1a9fa`, base `main@c76c81d79395bb7f242e321a9fdde1d1fc08e270`, no stashes, and no concurrent implementation agent. Scope is this existing W7C-3 task only; no table/column shape or hosted-deployment authority is transferred.
**Ownership transition:** Consolidated the temporary Play FAB/UI work into the existing W7C-3 branch without rewriting original commits. The consolidation merge has original W7C-3 HEAD `0f32b91` and W7C-2 merged main `c76c81d` as parents, and selects the already-audited combined UI tree. Original implementation history remains reachable. PR #740 is canonical; duplicate PR #741 is superseded/closed.
**Repository state last verified:** Preflight was clean at `df9a3fa7c06f7e820a600d234b262de4bed1a9fa`, matching GitHub PR #740 HEAD; base is `main@c76c81d79395bb7f242e321a9fdde1d1fc08e270`. Local fetch could not update `.git/FETCH_HEAD` due permission; remote main and PR head were read directly through GitHub API. This session now has a scoped, uncommitted local diff described below.
**Branch:** feat/w7c-3-active-workout-execution-ui
**Observed working-tree state:** Scoped uncommitted changes are limited to `.ai/tasks/README.md`, `.ai/tasks/w7c-3-play-fab-active-ui.md`, `apps/features/workout/lib/src/presentation/pages/active_workout_page.dart`, `apps/features/workout/lib/src/presentation/pages/save_workout_page.dart`, and `apps/features/workout/test/presentation/save_workout_page_test.dart`. No stashes listed.
**PR / tracker:** GitHub PR #740 / GitHub #739 / Linear TNYX-84
**Relevant execution surface:** apps/features/workout, apps/app routing, .ai task handoff
**Validation on exact source HEAD:** GitHub reports five successful PR-triggered workflows for `df9a3fa7` and a successful attribution guard. Local validation on the same source state passed `flutter test --no-pub` in `apps/features/workout` (**1,322 tests**), focused workout widgets (**66 tests**), `flutter analyze --no-pub` in `apps/features/workout` and `apps/app`, and `git diff --check`. Nearby-gyms Deno runtime tests and device/hosted integration were not run; previous Deno attempt was blocked fetching JSR `@std/assert`.
**Local delta after `df9a3fa7` (not yet committed/pushed):** `SaveWorkoutPage.onDiscard` awaits the canonical discard result, remains open and shows an error when persistence returns false, and only pops after confirmed success. `ActiveWorkoutPage` returns the controller's actual result. Two focused regression tests cover pending and failed discard persistence. The task brief records the exact proposed W7C metadata contract; no migration or W7 persistence code changed. `dart format` ran on changed Dart files; `flutter analyze --no-pub` in `apps/features/workout` reports no issues; focused Save/Active page tests passed (**39 tests**). Re-run `git diff --check` before commit/push.
**Current blockers:** Hosted project has only the ledger through `20261031142025`; W7B `20261106073920_user_workout_sessions.sql` is merged source but not deployed. The proposed W7C nullable metadata columns/V2 RPC require explicit shape approval. No real ad-hoc start or history-list contract exists; preview cannot report Save success. Google Places remains undeployed with quota/billing/abuse controls unverified. PR #740 has 17 unresolved threads and the independent review is `CHANGES_REQUESTED`; do not resolve threads without evidence or claim merge readiness.
**Tracker update:** Linear TNYX-84 remains `In Progress`; its live dependency relation blocks on TNYX-80/TNYX-81 and blocks TNYX-85/TNYX-88. GitHub #739 still carries historical UI-only scope; record the superseding real-save direction plus the separate schema/deployment gate. PR #740 remains open on `df9a3fa7`; latest review is `CHANGES_REQUESTED`, all 17 threads unresolved, and five workflows pass.
**Next exact action:** Obtain explicit owner approval/rejection of the exact additive W7C columns and V2 completion RPC proposal in this handoff before schema or Flutter persistence implementation; keep independent review fixes in the existing branch and retain the no-automatic-merge gate.

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

**Validation:** Commit `b888b084c51564a20450658e6d7a4674fd370993` is published but its Flutter CI failed. The local correction passes all 1,322 workout tests and both Workout/app analysis; the corrected state is pending push and exact-head CI. Deno test, device comparison, hosted persistence, and independent review remain pending.

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

**Status:** BLOCKED — source correction is locally validated but not yet published; exact-head CI/re-review are pending, and real-save title/date-time contract approval remains outstanding.

No hosted Supabase schema/RPC changes or deployments were made. Source changes do touch the checked-in Edge Function and `supabase/config.toml`. No merge authorization was given.

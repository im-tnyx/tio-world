# GitHub #667 / #357 / #260 — C3f Account Settings Route Composition

**Status:** In progress — PR #668 Ready for Review, source checks and Codex clean; final docs-head recheck pending
**Primary owner:** App routing/composition
**Affected platforms:** Flutter Android and iOS app

## Owner Approval and Scope Boundary
**Trigger:** New independently scoped route extraction slice.
**Approval status:** Approved for implementation **through merge gate, not merge**.
**Approval evidence:** Owner's 2026-10-24 instruction to start the GitHub #260 follow-up with fresh audit and carry it to merge gate.
**Approved boundary:** Extract only Account Settings route registration and its route-specific helpers into `apps/app/lib/app/routing/routes/account_settings_routes.dart`; leave global GoRouter, redirect, Splash, shell, other route groups unchanged.
**Explicit non-changes:** No UI/copy/layout change, Auth/OTP/session/verification/delete behavior change, provider contract/identity/lifetime change, Supabase/backend/RLS/SQL change, Workout/shell change, feature package move or merge.

## Active Handoff
**Planning owner:** TNYX-201 / GitHub #260 and #357
**Implementation owner:** ChatGPT GitHub-connector execution (single active owner for #667)
**Review owner:** Codex independent automated code review completed at `8dfa606b`, clean/no findings; formal GitHub APPROVED review not observed. Implementation-owner self-review is not independent.
**Implementation ownership state:** Handoff pending (source complete; validation/review gate)
**Ownership transition:** Not applicable (new, isolated slice)
**Repository state last verified:** 2026-10-24 remote protected GitHub `main@92e9af122cf71b599ea066d33eee2cdfc5f403f0`
**Branch:** `tnyx/issue-667-c3f-account-settings-routes`
**HEAD SHA:** Last fully reviewed/tested PR HEAD `8dfa606b0cfd9056a63602b8e809d877187e66aa`; this docs handoff update advances HEAD, so recheck live PR/CI before merge readiness.
**Observed working-tree state:** GitHub API-only execution. Local `G:\projects\Tio-World` checkout and `git status -sb` unavailable, NOT verified or modified.
**Observed uncommitted/dirty files:** Unknown in user Windows checkout; isolated GitHub branch contains only committed changes.
**PR / tracker:** https://github.com/im-tnyx/tio-world/pull/668 (Ready for Review on 2026-10-24 after green source-head CI); child #667, parents #357/#260, Linear TNYX-201
**Current implementation state:** Source extraction committed; root router 612 → 398 lines, new account route module 239 lines. No runtime/test validation claimed.
**Relevant execution surface:** GitHub connected owner account `im-tnyx`; Flutter tests/CI GitHub after PR.
**Validation completed at SHA:** PR HEAD `8dfa606b0cfd9056a63602b8e809d877187e66aa`: hosted Flutter CI run `40079224657` SUCCESS 5/5 Flutter/Dart jobs (analysis/Dart tests, app-workout, nutrition-onboarding, core-wear, aggregate); Commit attribution guard, attribution runner, docs diff hygiene SUCCESS (8/8 check runs). Earlier PR HEAD `43343f0a` also full SUCCESS. GitHub compare: ahead 4/behind 0, exactly 3 owned paths. Codex review on `8dfa606b` completed with no findings and no unresolved threads; not a formal GitHub APPROVED review.
**Validation remaining:** Recheck CI at final docs-only handoff HEAD; PR ready-review and bot/independent review, unresolved-thread gate and branch protection, user Windows local git diff and device parity unavailable. No Supabase/database changes applicable.
**Current blocker:** No verified source or CI defect at `8dfa606b`; formal GitHub APPROVED review not observed. Branch protection GET 403 prevents independent read of exact required checks. Codex automated review clean at `8dfa606b` (not formal APPROVED). Linear agent notes action returned tool-not-found. Local Windows git/device parity not observed.
**Open review finding IDs:** None yet.
**Next exact action:** Verify checks/review after this final docs-only update, inspect live PR merge status and report merge gate; remain Ready for Review, never merge without a separate owner instruction.

## 1. Discovery
### User Outcome
Smaller app-owned root router without changing any Account Settings user behavior.

### Success Criteria
One Account Settings route in app route module; same `AppRoutes.accountSettings.path`, root navigator key, Auth and profile data reads, fail-closed repository handling, email/phone verification, username update-only, delete-confirmed session handoff, provider invalidations and navigation.

### Scope
`router.dart`, new `routing/routes/account_settings_routes.dart`, focused `apps/app/test/app/account_settings_route_test.dart` only if useful, and this task brief.

### Non-Goals
No changes to `shell_route.dart` (separate 1,625-line audit candidate), `network_providers.dart`, `_NutritionLoadFailure`, Splash, Auth/Settings feature implementations, Supabase, mobile UI, callbacks' product semantics.

## 2. Codebase Exploration
### Verified Evidence
- Root `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.github/PUSH_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE.md` and task template reviewed.
- Canonical `docs/architecture/MODULE_OWNERSHIP.md`: `apps/app` owns route/provider composition; Settings owns Account presentation; Auth owns session/verification.
- `router.dart` 612 lines has direct Splash and Account Settings registrations; one `goRouterProvider`. Account route is after existing Body and Wellness route lists, with username/identity helper functions at root.
- Existing `buildBodyWeightRoutes` and `buildDailyWellnessRoutes` use one route builder under `app/routing/routes/`; no independent GoRouter is created.
- Existing `apps/app/test/app/account_settings_route_test.dart` exercises route navigation, username availability success/reserved case, repository callback and real field feedback.
- Existing `apps/app/test/app/router_provider_stability_test.dart`, `onboarding_root_logout_router_test.dart`, `app_mode_router_test.dart` and account/deletion tests are relevant regressions.
- #260 source checkpoint explicitly warns shell-route and Workout workflows are separately gated; #357 2026-10-22 comment proposed C3f Account Settings extraction after separate owner approval, now granted for this bounded slice.

## 3. Clarification
| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep root GoRouter/Splash | Frozen | Preserve startup and navigation authority | App |
| Move Account Settings helpers with route | Chosen | Helpers are only used by this route | App |
| Pass bootstrap state mark via callback | Chosen | Preserve existing callback ordering without exposing bootstrap internals in new module | App |
| Leave Nutrition failure/shell routing alone | Frozen | Separate owner classification; avoid scope creep | Follow-up |

## 4. Architecture Design
### Chosen Approach
`router.dart` assembles `...buildAccountSettingsRoutes(rootNavigatorKey: ..., markUnauthenticatedAfterAccountDeletion: ...)` in the same position. New route module retains original `Consumer`, provider reads, callbacks, fail-closed behavior, invalidations, and mounted checks. The only callback crossing the boundary marks the existing app bootstrap state unauthenticated at the original statement position.

### Ownership and Data Flow
Account Settings page (Settings feature) → app route dependency composition → Auth/Profile/Settings repository and use-case providers; no new data owner.

### Alternative Rejected
Moving Account Settings controller/verification/delete workflow into an unrelated feature or a new router; it risks behavior/security changes and is not justified for a route-only mechanical extraction.

### Failure and Accessibility States
Preserve username availability failure and conflict messages, unavailable repository errors, canceled OTP/mounted guards, delete use-case failure, best-effort local sign-out semantics and existing unchanged Settings UI/accessibility.

## 5. Implementation Plan
- [x] Extracted Account Settings route/helpers to app-owned route module in source commit `d41da17c` and kept original order.
- [x] GitHub source audit checked a single root `GoRouter`, one direct root Splash `GoRoute`, one new Account Settings `GoRoute`, unchanged OTP request/verify, save and post-delete callback sequence. Flutter compile/runtime checks pending.
- [x] Existing focused Account Settings and routing tests executed inside hosted app-workout shard; that shard passed at `43343f0a`. No new test needed for the mechanical extraction; no device parity claim.
- [x] Source-head and handoff-head hosted Flutter CI PASS at `43343f0a` and `8dfa606b`; PR is Ready for Review, Codex clean/no threads. Recheck this final docs-only HEAD; Codex is not GitHub formal APPROVED.

## 6. Quality Review
### Validation Run
Hosted [Flutter CI #40079224657](https://github.com/im-tnyx/tio-world/actions/runs/40079224657) succeeded at exact `8dfa606b` (5/5 workflow jobs), as did the two attribution checks and docs hygiene (8/8 total). Prior [Flutter CI #40078886038](https://github.com/im-tnyx/tio-world/actions/runs/40078886038) likewise succeeded. GitHub compare verified 3-path scope, and patch inspection found no added trailing whitespace. Recheck CI after this docs-only handoff update. **No local `git diff --check`, Flutter SDK execution or visual/device parity was observed.**

### Review Provenance
**Review source / link:** [Codex exact-head completed, no findings](https://github.com/im-tnyx/tio-world/pull/668#issuecomment-6382159580); [review receipt](https://github.com/im-tnyx/tio-world/pull/668#issuecomment-6382176724); GitHub PR #668
**Reviewer / relation to implementer:** Pending independent review
**Diff or commit SHA actually reviewed:** Source commit `d41da17c`; GitHub scope/patch static self-review at PR HEAD `43343f0a`.
**Review result and finding IDs/dispositions:** Codex at `8dfa606b` completed `has_any_findings=false`, `has_unresolved_findings=false`, with no major issue. No unresolved GitHub threads at Ready gate. Source mechanical comparison reconstructed original 7,165-character route block byte-for-byte after restoring indentation and bootstrap callback; all three helper functions byte-identical. Implementation-owner static review also found no concrete P1/P2/P3; **not formal independent GitHub APPROVED**.
**Independent review?** Yes, Codex automated review at exact `8dfa606b` with no findings. Formal human/independent GitHub APPROVED review not observed.
**Limitations and unmet required gates:** Local Windows checkout, device screenshots, Flutter SDK commands not available through this session. Use hosted CI for applicable checks; record any gaps accurately.

## 7. Final Handoff
**Changed Files:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/account_settings_routes.dart`, this task brief.
**Actual Behavior:** Source-equivalent refactor only. Behavioral parity still requires GitHub Flutter tests/review.
**Known Limitations:** Connector-only checkout visibility; branch protection direct read 403; formal GitHub APPROVED review and device parity not observed. Supabase/backend/schema untouched.
**Final Status:** REVIEW pending implementation/CI/review. No merge authorized.

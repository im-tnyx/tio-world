# GitHub #667 / #357 / #260 — C3f Account Settings Route Composition

**Status:** Validated / archived on 2026-10-24, after source PR #668 merged.
**Primary owner:** App routing/composition (`apps/app`)
**Affected platforms:** Flutter Android/iOS phone; no app release or device QA asserted.
**Task ownership:** Original implementation owner: `im-tnyx` via ChatGPT GitHub connector; independent formal review from `im-tio`. Source slice completed; no active implementation ownership remains for #667.

## Owner Approval and Frozen Scope

Owner's 2026-10-24 approval covered a bounded Account Settings route extraction **through merge gate only**. A subsequent owner-authorized merge completed PR #668 on 2026-10-24. This archive records that outcome; it does not grant merge authority to other PRs.

- Move only Account Settings route registration and route-local helpers into `apps/app/lib/app/routing/routes/account_settings_routes.dart`.
- Keep single `goRouterProvider`, root `GoRouter`, root navigator, Splash/redirect/bootstrap and other route groups in `apps/app/lib/app/router.dart`.
- Preserve username availability/conflict messages, Auth email/phone OTP verification, username-only Save, server-confirmed account deletion before local signout/bootstrap/invalidation/navigation, all existing mounted and error guards.
- Excluded: UI/copy/layout changes; Auth/session/account-delete behavior changes; provider identity/lifetime changes; Supabase/RLS/SQL/backend; Workout/shell or other routes.

## Verified Post-Merge Handoff

| Evidence | Verified result |
|---|---|
| Child issue | [GitHub #667](https://github.com/im-tnyx/tio-world/issues/667) CLOSED on 2026-10-24 (source work completed) |
| Implementation PR | [#668](https://github.com/im-tnyx/tio-world/pull/668) MERGED at 2026-10-24T08:59:47Z |
| Exact reviewed final PR HEAD | `f8527b699c12ca931b11fb02445d6b3cec64f1df` |
| Merge commit / verified `main` | `69f4e8643e22a9c96c47e0b99ed4c525a119f99e` |
| Final-head validation | [Flutter CI #40079634852](https://github.com/im-tnyx/tio-world/actions/runs/40079634852) 5/5 SUCCESS; [Docs Hygiene #40079634807](https://github.com/im-tnyx/tio-world/actions/runs/40079634807) SUCCESS; Commit attribution guard and runner SUCCESS (8 successful checks) |
| Post-merge verification | GitHub `main@69f4e864` 5/5 Flutter/Dart check-runs SUCCESS |
| Independent code review | `im-tio` GitHub **APPROVED** at exact final PR HEAD; author `im-tnyx`'s earlier COMMENTED self-review was **not** independent approval |
| Automated review | Codex code review completed at final `f8527b`, no findings and no unresolved findings; GitHub review threads: zero |
| Supplemental checks | Three Cursor check-runs NEUTRAL due service usage/quota limits. They are not security/code review passes; no concrete findings reported by those runs |
| Tracker state on archive audit | Parents [#260](https://github.com/im-tnyx/tio-world/issues/260) and [#357](https://github.com/im-tnyx/tio-world/issues/357) OPEN; [TNYX-201](https://linear.app/tnyx/issue/TNYX-201) In Progress. Do not close parent trackers for this child |
| Visibility limits | User Windows `G:\projects\Tio-World` local `git status`, `git diff --check`, local Flutter SDK execution, Android/iOS screenshots/device parity **not observed**. Branch-protection GET returned 403; PR independent review receipt reported attribution as sole required check and empty ruleset list |
| Agent notes | Linear `get_agent_context` returned tool-not-found during archive audit; Linear TNYX-201 issue itself was readable |

Canonical app route composition stays with `apps/app`; Account Settings page and Auth verification behavior stay with their existing feature owners. The source merge is not evidence of a distributed mobile app release. Future `shell_route.dart` cleanup belongs to separate approved scope and is not part of #667.

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

## 5. Implementation Outcome

- [x] Root `router.dart` reduced from 612 to 398 lines and delegates one existing Account Settings route to `buildAccountSettingsRoutes` at its original registration position.
- [x] Extracted route plus three helpers into 239-line `account_settings_routes.dart`, without a second GoRouter or changing the account deletion bootstrap callback's order.
- [x] PR #668 changed three scoped paths only (root router, new route module, original task brief); no Flutter test, Supabase, UI or other source files changed.
- [x] Existing `apps/app/test/app/account_settings_route_test.dart` coverage ran through the hosted Flutter CI app shard; final-head 5/5 Flutter/Dart SUCCESS.
- [x] Exact-head independent approval, Codex no-findings and zero threads verified; source merged. Parent #260/#357 and TNYX-201 remain active.
- [ ] Owner-local Windows `git diff --check` and physical Android/iOS visual parity were not observed; do not retroactively mark them as passed.

## 6. Quality Review and Risk Disposition

No confirmed P0/P1/P2/P3 defect was reported in the independent exact-head review. The formal `im-tio` approval compared the original Account Settings route and three helper contracts, including username fallback, OTP request/verify, callback order, account-deletion handling, route registration and provider lifecycle. The clean Codex bot review does **not** replace the independent GitHub approval. Cursor quota-limited neutral checks do **not** count as a completed security assessment.

Requiredness was separately recorded in the GitHub review: attribution required and successful; Cursor supplemental and NEUTRAL. Direct branch-protection read was unavailable to the archival auditor (403), so do not claim independent verification of those protection settings. No hosted database/security-sensitive source was changed by #668.

## 7. Final Handoff

**Final source status:** Validated source merge; child #667 completed. This archival document is a historical record, not an active task or release authorization.
**Canonical references:** [Module Ownership](../../docs/architecture/MODULE_OWNERSHIP.md), [Architecture](../../docs/architecture/ARCHITECTURE.md), [source PR #668](https://github.com/im-tnyx/tio-world/pull/668).
**Remaining parent scope:** GitHub #260/#357 and Linear TNYX-201 retain further router/shell ownership and broader acceptance work. No parent closure or separate feature activation is implied.

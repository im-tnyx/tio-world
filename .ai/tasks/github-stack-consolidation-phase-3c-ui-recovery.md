# GitHub stack consolidation — Phase 3C UI recovery

**Status:** In progress
**Primary owner:** Core reusable UI; Onboarding, Account Setup and Welcome consumers
**Affected platforms:** Flutter phone UI; composed Phone/Wear validation
**Branch:** `codex/github-stack-consolidation`
**Existing Draft PR:** #155, base `main`

## 1. Discovery

Recover previously completed stranded UI work, not a new feature or redesign.
Starting consolidation HEAD: `76c0f527eb5d43b2fcb1874aa45f8f5e410e4e1d`.
Historical preservation HEAD: `99314ec05208b375c99254f103f35763c769ddd3`.

Recovery sources:
- `0bf8ca540edc0617173081fcb49aba6194d50b46`: Core presenters.
- `5779ec854ed893154da4b8aeac38de44897210c4`: Onboarding adoption.
- `99314ec05208b375c99254f103f35763c769ddd3`: selected Account Setup/Welcome hunks.

Success requires selective inclusion, protected-source retention, focused UI
checks, repository-wide analyze/tests, both Android debug builds, one new
commit and a normal push updating existing Draft #155. Remote CI is reported
only for the new exact head; merge/cleanup require a separate task.

### Exact historical recovery paths

- `.ai/tasks/account-setup-mobile-info-action-parity.md`
- `.ai/tasks/onboarding-bottom-sheet-core-reuse.md`
- `.ai/tasks/welcome-signin-footer-theme-contrast.md`
- `apps/app/test/app/welcome_accessibility_test.dart`
- `apps/core/lib/src/theme/README.md`
- `apps/core/lib/src/ui/components/sheets/sheets.dart`
- `apps/core/lib/src/ui/components/sheets/tio_confirmation_bottom_sheet.dart`
- `apps/core/lib/src/ui/components/sheets/tio_information_bottom_sheet.dart`
- `apps/core/test/ui/components/tio_information_bottom_sheet_test.dart`
- `apps/features/account_setup/lib/src/presentation/account_setup_flow_page.dart`
- `apps/features/account_setup/test/presentation/account_setup_flow_page_test.dart`
- `apps/features/onboarding/lib/src/presentation/pages/onboarding_flow_page.dart`
- `apps/features/onboarding/lib/src/presentation/screens/targets/goal_pace_screen.dart`
- `apps/features/onboarding/lib/src/presentation/widgets/onboarding_data_collection_sheet.dart`
- `apps/features/onboarding/lib/src/presentation/widgets/widgets.dart`
- `apps/features/onboarding/test/presentation/body_goal_weight_wheel_regression_test.dart`
- `apps/features/welcome/lib/src/presentation/screen/welcome_screen.dart`

This brief is the only additional allowed path (18 total).

### Non-goals

No whole preserve-branch merge, stale Auth/Supabase history, new features,
routing redesign, dependency/native/workflow changes, attachment access or
cleanup, worktree creation, alternate checkout, history rewrite, new PR,
Ready transition, main merge, historical PR/branch mutations or production
operations. Existing untracked attachments remain untouched.

## 2. Codebase Exploration

Read applicable AGENTS, workflow/task conventions, push/PR templates, canonical
ownership/setup docs, Core theme README and design-system guidance, relevant
package source/tests, and Phase 2/3A/3B evidence. Current user scope overrides
historical worktree/prune suggestions and old normalization allowances.

Fresh root/branch/HEAD checks match the starting checkpoint. Tracked state is
clean. Exactly one active checkout exists; stop if any unexpected worktree
appears. Fetched origin/tags without pruning. Both remote pins match. #155 is
OPEN/Draft, base main, exact checkpoint head.

Core already exposes TioSheet, TioConfirmationCard, TioButton and
TioInlineInfoAction. Information shells repeat across Onboarding and Account
Setup. Specialized pickers remain separate. Newer TioSocialButton README
content must survive additive sheet documentation.

GoalPace current file equals effective #132 `2b82722b2097d3d81399f62f89b37eff304b6209`.
Its Phase 3A changes are only _formatPace (UnitConverters) and _formatWeight
(UnitFormatters). Recover the information/attention modal bodies only; retain
UnitPreferences, warning copy, screen layout, projections and unit conversions.
The current warning presenter is named _showAttentionSheet.

Account Setup has newer Email/contact bridge behavior. Only
_showMobileInformation is replaced; hydration, Email handling, completion and
navigation remain current. Welcome changes only two footer semantic colors;
hero, layout, callbacks and global theme remain current.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Existing checkout only | Required | No new worktree; unexpected worktree means STOP |
| Select path/hunk intent | Approved | Mixed historical commit contains excluded history |
| Shared sheets and footer colors | Approved recovery | No redesign beyond historical UI intent |
| Additive Core README | Required | Preserve newer SocialButton docs |
| Refresh historical task evidence | Approved | Historical stalled tests are not current PASS |
| One commit, normal existing-branch push | Approved after local gates | Keep #155 Draft; no main merge |

## 4. Architecture Design

Core owns generic modal shell, safe area, semantic styling, close/actions and
confirmation result. Features own copy, warning semantics, navigation, state
and persistence. Consume through the public core boundary. No new tokens,
feature-specific core logic, compatibility adapters or backend assumptions.

Rejected: whole-file rollback of Account Setup/GoalPace/Welcome/README,
wholesale cherry-pick, retaining duplicate generic sheets and tooling upgrades.

Visual baseline: current source/tests inspected at starting checkpoint.
Historical presenters define the approved shared shell. Their geometry differs
from old bespoke information shells intentionally; verify historical fidelity,
compact width, safe area and light/dark themes. Welcome geometry must remain
unchanged; only surface text/link roles change.

## 5. Implementation Plan

- [x] Verify preflight and inspect source/historical hunks.
- [x] Core presenters/export/test, then additive README.
- [x] Onboarding consumers and GoalPace combined Units/UI proof.
- [x] Account Setup and Welcome selective recovery.
- [x] Refresh historical evidence; exact 18-path/protected-source audit.
- [x] Focused tests and visual/widget states; affected analyze.
- [x] Repository analyze, serialized full tests, Phone/Wear debug builds.
- [x] One new commit; pre-push audit; normal push to existing branch.
- [x] Verify #155 remains Draft, exact-head CI; outside report; STOP.

## 6. Quality Review

### Validation Run Results

- `git diff --check`: PASS (clean)
- `flutter analyze` on `apps/core`: PASS (no issues, 29.2s)
- `flutter analyze` on `apps/features/onboarding`: PASS (no issues, 20.9s)
- `flutter analyze` on `apps/features/account_setup`: PASS (no issues, 3.0s)
- `flutter analyze` on `apps/app`: PASS (no issues, 17.0s)
- Focused widget/contract tests:
  - `apps/core`: 2/2 tests PASS
  - `apps/features/onboarding` regression: 5/5 tests PASS
  - `apps/features/account_setup`: 8/8 tests PASS
  - `apps/app` welcome accessibility: 4/4 tests PASS
- Full serialized test suite:
  - `apps/core`: 114/114 tests PASS
  - `apps/shared`: 30/30 tests PASS
  - `apps/features/onboarding`: 435/435 tests PASS
  - `apps/features/account_setup`: 37/37 tests PASS
  - `apps/features/auth`: 159/159 tests PASS
  - `apps/features/nutrition`: 21/21 tests PASS
  - `apps/features/profile`: 59/59 tests PASS
  - `apps/app`: 228/228 tests PASS
  - `apps/wear`: 9/9 tests PASS
  - Total: 1,092 tests PASS across workspace packages
- Android Debug Builds:
  - Phone Android Debug APK (`apps/app`): PASS (`app-debug.apk` built in 67.5s; non-blocking NDK warning recorded)
  - Wear Android Debug APK (`apps/wear`): PASS (`app-debug.apk` built in 21.3s)

Required retention: Phase 3A Units, Phase 3B workflow, #152 Auth/Account/Nutrition,
Supabase, native config, Wear and attachments. No visual regressions detected.

## 7. Final Handoff

Implementation and all local gates complete. Ready for commit, push, and CI inspection.

**Current status:** COMPLETE — local validation PASS.

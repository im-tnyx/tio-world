# GitHub #24 Phase #24-D — Account Settings Username Migration

**Status:** Ready for review (Draft PR, device acceptance pending)
**Primary owner:** `apps/core` (`TioUsernameInputField`) + `apps/features/settings` (`AccountSettingsPage`) + `apps/app` (`router.dart` composition)
**Affected platforms:** Flutter phone UI

## Owner Approval and Scope Boundary

**Approval status:** Approved as a bounded core-extension + consumer-migration slice, explicitly requested by the owner as GitHub #24 Phase #24-D.
**Approved boundaries:** Migrate `AccountSettingsPage`'s hand-rolled username field (raw `TextField` + local debounce/status/suggestion state) to canonical `TioUsernameInputField`, extending core only with an evidenced, non-speculative appearance/capability contract; wire the real `ProfileAccountRepository.checkUsernameAvailability` in app composition.
**Explicit non-changes:** Auth username/email/password fields, `EmailLoginPage`, mobile-number migration, Profile selection rows, `TioSelectionField`, Nutrition "Other", onboarding inline "Other", Step Target, GitHub #197/#183/#198/#199 (unrelated onboarding findings), Workout fields (#24-C, already merged), Supabase RPCs/policies/schema, GitHub #24 closure.

## Active Handoff

**Implementation owner:** Claude (Claude Code). Recorded before source mutation, matching the repository's disabled-AI-attribution policy (`CONTRIBUTING.md`, `.claude/settings.json`) — no `Co-Authored-By` trailer on this slice's commits.
**Branch:** `refactor/issue-24-d-account-settings-username-migration`
**Base:** `main` @ `5f64351fcd6cdfe60604ca8165ad77e5b627ec9d` (PR #196 / #24-C merge)
**Current state:** Implemented, validated locally, ready to publish as a Draft PR.
**Validation remaining:** Exact-head repository Flutter CI, then owner physical-device acceptance.

## 1. Discovery

### Fresh pre-flight verification (before any implementation)

- PR #196 / Phase #24-C: **MERGED** at `5f64351f`.
- GitHub #24: **OPEN**.
- No existing Linear tracker for #24-D found; created **TNYX-149**, linked to GitHub #24.
- `main` clean, no overlapping open PR touching these files.

### Property-by-property audit — Account Settings vs canonical, before touching either

| Property | Account Settings (before) | `TioUsernameInputField` (outlined, before) |
|---|---|---|
| Shape | fixed-height (56dp) filled capsule row, `Container`>`Row`>borderless `TextField` | floating-label Material `OutlineInputBorder` field |
| Radius | `TioRadius.lg` (16dp) | `TioRadius.lg` (16dp) — same token |
| Border alpha (normal/status) | `TioAlpha.alpha40` / `alpha80` | `TioOpacity.opacity40` (fixed, not status-tinted the same way) |
| Border width (normal/status) | `TioStroke.width1` / `width15` | fixed `outlineWidth`/`focusedOutlineWidth` |
| Prefix icon | `Icons.alternate_email_rounded`, 22dp | `Icons.alternate_email`, 20dp, inside `InputDecoration.prefixIcon` |
| Hint | `'username'` | `'e.g. your.name'` (caller-overridable) |
| Debounce | 450ms | 400ms |
| Async correctness | **no generation guard, no stale-handle guard** | generation counter + stale-handle guard (`_availabilityGeneration`) |
| Suggestion recheck on tap | **none** — applied suggestion marked available without rechecking the server | full recheck via `_onInputChanged` |
| Lowercase | only at debounce-check time (raw keystrokes not forced lowercase) | live, per-keystroke via `_LowercaseTextInputFormatter` |
| Character filter | `FilteringTextInputFormatter.allow([a-zA-Z0-9_.])` | none built in |
| Availability source (production) | **`router.dart` never wired `onCheckUsernameAvailability`** → hand-rolled hardcoded demo fallback list (`admin`/`tio`/`fitness`/`user`/`coach`/`member`) shown to real users | consumer-supplied, real server-backed in Account Setup |
| `availabilityRefreshToken` (post-save-race recheck) | not present | present, used by `UsernameStep` |

**Conclusion:** the two are a genuinely different visual contract (fixed capsule row vs. floating-label outline), not a stray inconsistency — direct widget substitution would silently change Account Settings' appearance. Per the task's explicit constraint, this was not accepted silently.

### Classification (per correction-pass request — this is not a behavior-neutral refactor)

| Aspect | Classification |
|---|---|
| Visual contract (capsule geometry/colors/icon/hint) | **Preserved** |
| Field state/logic ownership (debounce, status, suggestions) | **Refactored** — moved from page-local duplicate state into the reusable core widget |
| Async race correctness (generation guard, stale-handle guard) | **Fixed** — Account Settings previously had neither |
| Production availability source | **Corrected** — from a hardcoded demo fallback list to the existing `ProfileAccountRepository` (already used by Account Setup; not a new repository) |
| Suggestion verification on tap | **Hardened** — now rechecked against the server instead of assumed available |
| Username normalization (live lowercase) | **Aligned** with the canonical username contract already used elsewhere |
| Final uniqueness-race UX (save-time conflict) | **Hardened** — was previously an uncaught generic failure; now a specific message + automatic recheck |
| Current/persisted-username initial and revert status | **Preserved** — see Correction Pass below; this required a source fix, not just a test fix, to actually hold |

PR #200 does not claim to be a behavior-neutral refactor; the items above marked Fixed/Corrected/Hardened/Aligned are disclosed, evidenced improvements, not incidental side effects.

### Real production gap found during audit

`apps/app/lib/app/router.dart`'s `AccountSettingsPage(...)` composition never passed `onCheckUsernameAvailability`. This means the hand-rolled hardcoded demo-fallback list in the old implementation was — and until this slice's `router.dart` change, remained — what real users saw when checking username availability in Account Settings, not a real server check. Fixed as part of this slice's explicit scope (wiring `onCheckUsernameAvailability`), not treated as a pre-existing issue to defer.

## 2. Core rule applied

`TioUsernameInputField` could not reproduce Account Settings' capsule contract, so the smallest reusable, domain-neutral addition was made:

1. **`TioUsernameFieldAppearance` enum** (`outlined` default / `capsule`) — shape-based naming, matching the precedent set by `TioInputVariant`'s `standard`/`numericEditor`/`multiline` naming. Not `settingsVariant`/`accountSettingsStyle`/feature-named.
2. **`extraInputFormatters`** — plumbing-only `List<TextInputFormatter>?`, appended after core's own lowercase/length formatters. Lets Account Settings keep its character allow-list without forcing that policy onto every consumer (Account Setup has no such filter).
3. **New token family** (`TioInputTokens.usernameCapsule*`) mirroring the evidenced capsule geometry/colors exactly (56dp height, 22dp icon, `TioAlpha.alpha40`/`alpha80` borders) — kept as a **separate** token family from the existing `username*` outlined tokens (no normalization; the two are evidenced, intentionally different contracts, matching the repo's standing "no 14↔16dp normalization" policy).
4. The suggestion-pill widget (`_buildSuggestions`) was factored into a shared helper used by both appearances — geometry/tap-behavior are identical between them; only the border alpha and the optional "Suggestions:" caption differ, both evidenced.

**Not added:** anything not evidenced by Account Settings' real contract. No `TioAccountSettingsUsernameField`. No API surface beyond what these two consumers demonstrate.

### Intentional behavior changes (disclosed, not hidden)

- **Async correctness fixed.** Account Settings gains the generation-invalidation guard and stale-handle guard that Account Setup already had; Account Settings previously had neither. Proven with new race-condition tests (rapid retyping, and reverting to the current persisted username while a stale check is in flight).
- **Suggestion tap now rechecks the server** instead of locally marking the suggestion "available" without verification.
- **Live per-keystroke lowercase** instead of lowercase applied only after the debounce fires.
- **Real server-backed availability** (`ProfileAccountRepository.checkUsernameAvailability`, wired in `router.dart`) replaces the hardcoded demo fallback list that was silently live in production.
- **Save-time conflict handling added.** `UsernameUnavailableException` from the final database-uniqueness race (already thrown by `ProfileAccountRepository.updateUsername`, previously uncaught by Account Settings beyond a generic try/catch) now surfaces a specific message and bumps `availabilityRefreshToken` to force a fresh recheck, mirroring `UsernameStep.submit()`.
- **Debounce timing**: 450ms → 400ms (core's fixed value). Judged immaterial — not user-observable as a behavior difference, not called out as a device-acceptance item.

No 14dp↔16dp normalization performed. No Supabase RPC, DB policy, or schema change — `ProfileAccountRepository.checkUsernameAvailability`/`updateUsername` already existed and were already used elsewhere (Account Setup); Account Settings now reuses the same repository, not a new one.

## 3. Implementation

- [x] `TioUsernameFieldAppearance.capsule` + `_buildCapsule()` in `tio_username_input_field.dart`, mirroring `TioMobileNumberField`'s existing `Container`>`Row`>borderless-`TextField` structure.
- [x] `extraInputFormatters` param, appended after core's built-in formatters in both appearances.
- [x] New `usernameCapsule*` token family in `TioInputTokens`.
- [x] `outlined` appearance (Account Setup) unchanged — regression-tested explicitly.
- [x] `AccountSettingsPage`: removed the duplicate local `UsernameAvailabilityResult` class, `_UsernameStatus` enum, `_debounceTimer`, `_suggestions`, `_usernameFeedback` state, `_onUsernameInput`/`_performAvailabilityCheck`/`_applySuggestion` methods, and the raw `Container`+`TextField` username block. Replaced with `TioUsernameInputField(appearance: .capsule, ...)`, retaining only page-level `_usernameStatus` (via `onStatusChanged`) and `_usernameAvailabilityRefreshToken` for Save-button gating and post-conflict recheck.
- [x] `onCheckUsernameAvailability`'s type now resolves to core's `UsernameAvailabilityResult` (the local duplicate was a byte-for-byte copy with zero other consumers — confirmed via repository-wide grep before deletion).
- [x] `_handleSave` now catches a save-time username conflict and bumps the refresh token, mirroring `UsernameStep.submit()`. (The first pass caught `UsernameUnavailableException` directly and added a `tio_feature_profile` dependency to do so; the correction pass replaced this with core's `TioUsernameConflictException` and removed that dependency again — see Correction Pass Finding 2. Net effect on `main`: no change to `apps/features/settings/pubspec.yaml`.)
- [x] `router.dart`: wired `onCheckUsernameAvailability` to `profileAccountRepositoryProvider.checkUsernameAvailability`, with a reason-based message mapping mirroring `UsernameStep._availabilityMessage` exactly (`_accountSettingsUsernameMessage`).
- [x] Existing Settings tests (`account_settings_page_test.dart`, `account_settings_save_failure_test.dart`, and unrelated Settings suites) preserved unmodified and pass unchanged — the positional `find.byType(TextField)` indexing still resolves correctly because the field's own internal `TextField` occupies the same tree position.
- [x] New focused tests: capsule rendering, `extraInputFormatters` enforcement, no-callback-cannot-fake-success, checking→available, unavailable+suggestions, suggestion-tap-rechecks, stale-check-cannot-overwrite-newer-input, **revert-to-current-username-while-stale-check-in-flight**, save-time conflict handling with refresh-token-driven recheck.
- [x] Core: new capsule-appearance test group (5 tests) plus the explicit revert-to-current-username race test on the `outlined` appearance, per the task's explicit requirement.

## 3a. Correction Pass (post-review, before device acceptance)

A fresh review of head `d94f0c06` found two real issues before device acceptance. Both are fixed below; neither was a test-only fix.

### Finding 1 — current/persisted username was not preserved as idle

`TioUsernameInputField` already had pre-existing (pre-#24-D) logic that rendered `available` whenever the typed value matched `currentUsername`, both on initial mount (`initState`) and when the user typed back to it (`_onInputChanged`). Before #24-D, no production consumer passed `currentUsername` at all — `UsernameStep` (Account Setup) never wires it, so this branch was dead code. Wiring `currentUsername: widget.username` in the new `AccountSettingsPage` usage activated it for the first time, which silently changed Account Settings' contract: the old hand-rolled implementation always started `idle` (neutral border, no icon) for the already-persisted username, never `available`.

**Fix:** changed the current-username-match outcome in `tio_username_input_field.dart` from `available` to `idle`, and removed the now-empty `initState` override (the `_status` field's own `TioUsernameStatus.idle` default already covers it). This is evidenced by the *only* real consumer of `currentUsername` (Account Settings, which needs idle) — not a new parameter, no `settingsMode`/`accountSettingsBehavior` flag. `UsernameStep` is untouched and unaffected: since it never passes `currentUsername`, `_normalizedCurrentUsername` is always `''` there, so this branch can never match regardless of which status it resolves to.

New/updated tests:
- `apps/features/settings/test/presentation/account_settings_page_test.dart`: added "renders the persisted username in a neutral idle state" (no icon, normal alpha40/width1 border); corrected "reverting to the current username..." to expect no icon (was incorrectly asserting the available check mark) both immediately on revert and after the stale in-flight check resolves.
- `apps/features/account_setup/test/presentation/username_step_test.dart`: added a dedicated regression proving Account Setup's own behavior (editing away then back to the persisted username resolves `available` via a **real recheck**, unaffected by the core default change) is unchanged.

### Finding 2 — `tio_feature_settings → tio_feature_profile` dependency

Re-audited whether `AccountSettingsPage` needs to import `tio_feature_profile` at all just to catch `UsernameUnavailableException`/`UsernameAvailabilityReason` for save-time conflict handling. Existing precedent (`tio_feature_account_setup` already depends on `tio_feature_profile` for the same types) is not sufficient justification on its own if the presentation package can express the same behavior through an existing/near-existing boundary instead.

**Decision: removed the dependency.** Added a small, domain-neutral `TioUsernameConflictException` to `tio_core` (co-located with `UsernameAvailabilityResult` in `tio_username_input_field.dart`) carrying only a pre-resolved `message`. `router.dart` (which already depends on both `tio_core` and `tio_feature_profile`) now catches `UsernameUnavailableException` at the composition boundary, resolves the reason-based message itself (`_accountSettingsUsernameConflictMessage`, mirroring `UsernameStep._saveConflictMessage`), and re-throws `TioUsernameConflictException`. `AccountSettingsPage` catches only the core type and no longer imports `tio_feature_profile` at all. `apps/features/settings/pubspec.yaml`'s `tio_feature_profile` dependency was removed (`flutter pub get` confirms it is "no longer being depended on").

This keeps the domain-specific reason→message policy where it already lives for Account Setup's equivalent case (composition/app layer, not a feature-presentation package), and follows the same established pattern already used for `UsernameAvailabilityResult`/`TioUsernameStatus` as core-owned, domain-neutral mediating types between features. It is a small, targeted addition (one ~10-line class), not a larger refactor.

### Finding 3 (self-identified while addressing the above) — production wiring coverage

The reviewer noted that a fully-green app test suite without any test observing the new `router.dart` availability wiring is not sufficient evidence for that newly introduced production path. Added `apps/app/test/app/account_settings_route_test.dart`, driving the real `goRouterProvider` (same harness pattern as `body_weight_route_test.dart`) with a fake `ProfileAccountRepository` override, navigating to `AppRoutes.accountSettings.path`, and asserting both an available and a reason-specific unavailable result actually reach `TioUsernameInputField`'s rendered status. No live Supabase call.

## 4. Quality Review

### Validation Run

```text
dart format  (all changed/added files, correction pass included)
PASS — 0 changed (already formatted)

flutter analyze  # apps/core
PASS — No issues found

flutter test  # apps/core
PASS — 177 tests (was 171 before this slice; +6: capsule appearance group (5)
       + revert-to-current-username race test (1); idle-default fix required
       no test-count change in core, only a corrected default)

flutter analyze  # apps/features/settings
PASS — No issues found

flutter test  # apps/features/settings (full package)
PASS — 192 tests (was 182 before this slice; +10: +9 from the initial
       migration, +1 "renders the persisted username in a neutral idle
       state" from the correction pass; the "reverting to the current
       username" test's assertions were corrected in place, not added)

flutter analyze  # apps/features/account_setup
PASS — No issues found

flutter test  # apps/features/account_setup (full package)
PASS — 38 tests (was 37 before the correction pass; +1 regression proving
       Account Setup's current-username behavior is unaffected)

flutter analyze  # apps/app
PASS — No issues found

flutter test  # apps/app (full package)
PASS — 267 tests (was 266 before the correction pass; +1:
       account_settings_route_test.dart, production wiring coverage)

git diff --check
PASS
```

### Repository raw-field audit — proof

```text
Before this slice: 1 raw TextField in account_settings_page.dart (username) +
                    1 raw TextField in account_settings_page.dart (email) = 2
                    1 raw TextField (outlined) in tio_username_input_field.dart

After this slice:  1 raw TextField in account_settings_page.dart (email only)
                    2 raw TextField (outlined + capsule) in
                      tio_username_input_field.dart (core's own reusable
                      implementation — expected, not an app-level raw field)

Net: Account Settings' own file drops from 2 to 1 raw TextField (username
migrated, email intentionally out of scope). Core's reusable component gained
one internal TextField because it now implements two appearances instead of
one — this is the reusable implementation itself, not new app-level
duplication.
```

### Self-review findings

- **Cross-feature dependency avoided.** `tio_feature_settings` does **not** depend on `tio_feature_profile` (see Correction Pass Finding 2) — `TioUsernameConflictException` (core) carries the resolved message instead.
- **`onUsernameChanged` forwarding**: Account Settings previously called `widget.onUsernameChanged` with the raw untrimmed/uncased keystroke value; it now receives core's normalized (trimmed + lowercased) value on every keystroke, matching `UsernameStep`'s own forwarding pattern. `router.dart` does not currently wire `onUsernameChanged` at all (grep-confirmed), so this has no production effect today.
- **Debounce timing** (450ms → 400ms) is a minor, non-user-observable behavior delta from adopting core's fixed value; not treated as a visual regression requiring device sign-off, but disclosed above for completeness.

## 5. Final Handoff

### Changed Files

- `apps/core/lib/src/theme/tokens/components/tio_input_tokens.dart`
- `apps/core/lib/src/ui/components/inputs/tio_username_input_field.dart`
- `apps/core/test/ui/components/tio_username_input_field_test.dart`
- `apps/features/settings/lib/src/presentation/pages/account_settings_page.dart`
- `apps/features/settings/test/presentation/account_settings_page_test.dart`
- `apps/features/account_setup/test/presentation/username_step_test.dart`
- `apps/app/lib/app/router.dart`
- `apps/app/test/app/account_settings_route_test.dart` (new)
- `.ai/tasks/issue-24d-account-settings-username-migration.md`

9 files in the PR's net diff against `main`. `apps/features/settings/pubspec.yaml` / `pubspec.lock` appear in neither: the first commit added the `tio_feature_profile` dependency and the correction pass removed it, so the dependency never lands on `main`.

### Actual Behavior

Account Settings' username field keeps its exact prior visual contract (56dp capsule row, 16dp radius, `TioAlpha.alpha40`/`alpha80` borders, `alternate_email_rounded` icon, `'username'` hint, same character filtering, idle/neutral state for the already-persisted username) while gaining: async-correctness guards, suggestion-tap recheck, real server-backed availability, and save-time conflict handling with automatic recheck — all previously missing or fabricated locally.

### Known Limitations / Out of Scope

Email field in `AccountSettingsPage` remains a raw `TextField` (untouched, explicitly out of scope). Mobile-number field already uses `TioMobileNumberField` (pre-existing, untouched).

### Final Status

`AWAITING DEVICE ACCEPTANCE` — implementation, tests, and CI complete; do not merge until owner physical-device sign-off per the checklist below.

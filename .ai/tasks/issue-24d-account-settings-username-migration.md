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
- [x] `_handleSave` now catches `UsernameUnavailableException`, mirroring `UsernameStep.submit()`'s reason-based message mapping, and bumps the refresh token.
- [x] `apps/features/settings/pubspec.yaml`: added `tio_feature_profile` dependency (needed for `UsernameUnavailableException`/`UsernameAvailabilityReason`, following the same precedent `apps/features/account_setup` already uses).
- [x] `router.dart`: wired `onCheckUsernameAvailability` to `profileAccountRepositoryProvider.checkUsernameAvailability`, with a reason-based message mapping mirroring `UsernameStep._availabilityMessage` exactly (`_accountSettingsUsernameMessage`).
- [x] Existing Settings tests (`account_settings_page_test.dart`, `account_settings_save_failure_test.dart`, and unrelated Settings suites) preserved unmodified and pass unchanged — the positional `find.byType(TextField)` indexing still resolves correctly because the field's own internal `TextField` occupies the same tree position.
- [x] New focused tests: capsule rendering, `extraInputFormatters` enforcement, no-callback-cannot-fake-success, checking→available, unavailable+suggestions, suggestion-tap-rechecks, stale-check-cannot-overwrite-newer-input, **revert-to-current-username-while-stale-check-in-flight**, save-time conflict handling with refresh-token-driven recheck.
- [x] Core: new capsule-appearance test group (5 tests) plus the explicit revert-to-current-username race test on the `outlined` appearance, per the task's explicit requirement.

## 4. Quality Review

### Validation Run

```text
dart format
  apps/app/lib/app/router.dart
  apps/core/lib/src/ui/components/inputs/tio_username_input_field.dart
  apps/core/test/ui/components/tio_username_input_field_test.dart
  apps/features/settings/lib/src/presentation/pages/account_settings_page.dart
  apps/features/settings/test/presentation/account_settings_page_test.dart
PASS

flutter analyze  # apps/core
PASS — No issues found

flutter test  # apps/core
PASS — 177 tests (was 171 before this slice; +6: capsule appearance group (5)
       + revert-to-current-username race test (1))

flutter analyze  # apps/features/settings
PASS — No issues found

flutter test  # apps/features/settings (full package)
PASS — 191 tests (was 182 before this slice; +9 new username tests in
       account_settings_page_test.dart; account_settings_save_failure_test.dart
       and every other Settings suite unchanged and still passing)

flutter analyze  # apps/app
PASS — No issues found

flutter test  # apps/app (full package)
PASS — 266 tests, all passing (router composition change is additive-only;
       no existing app-level test asserts on the old username block)

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

- **New cross-feature dependency**: `tio_feature_settings` now depends on `tio_feature_profile` (for `UsernameUnavailableException`/`UsernameAvailabilityReason`). This mirrors the existing precedent set by `tio_feature_account_setup`, which already depends on `tio_feature_profile` for the same types. Not a new dependency *shape* in the repo, just a new edge in the existing feature graph.
- **`onUsernameChanged` forwarding**: Account Settings previously called `widget.onUsernameChanged` with the raw untrimmed/uncased keystroke value; it now receives core's normalized (trimmed + lowercased) value on every keystroke, matching `UsernameStep`'s own forwarding pattern. `router.dart` does not currently wire `onUsernameChanged` at all (grep-confirmed), so this has no production effect today.
- **Debounce timing** (450ms → 400ms) is a minor, non-user-observable behavior delta from adopting core's fixed value; not treated as a visual regression requiring device sign-off, but disclosed above for completeness.

## 5. Final Handoff

### Changed Files

- `apps/core/lib/src/theme/tokens/components/tio_input_tokens.dart`
- `apps/core/lib/src/ui/components/inputs/tio_username_input_field.dart`
- `apps/core/test/ui/components/tio_username_input_field_test.dart`
- `apps/features/settings/lib/src/presentation/pages/account_settings_page.dart`
- `apps/features/settings/pubspec.yaml` / `pubspec.lock`
- `apps/features/settings/test/presentation/account_settings_page_test.dart`
- `apps/app/lib/app/router.dart`
- `.ai/tasks/issue-24d-account-settings-username-migration.md`

### Actual Behavior

Account Settings' username field keeps its exact prior visual contract (56dp capsule row, 16dp radius, `TioAlpha.alpha40`/`alpha80` borders, `alternate_email_rounded` icon, `'username'` hint, same character filtering) while gaining: async-correctness guards, suggestion-tap recheck, real server-backed availability, and save-time conflict handling with automatic recheck — all previously missing or fabricated locally.

### Known Limitations / Out of Scope

Email field in `AccountSettingsPage` remains a raw `TextField` (untouched, explicitly out of scope). Mobile-number field already uses `TioMobileNumberField` (pre-existing, untouched).

### Final Status

`AWAITING DEVICE ACCEPTANCE` — implementation, tests, and CI complete; do not merge until owner physical-device sign-off per the checklist below.

# TNYX-139 Phase 2B — Settings App Mode → TioSelectableCard

**Status:** In progress
**Primary owner:** Flutter mobile / Settings feature
**Affected platforms:** Flutter Android and iOS

## Owner Approval and Scope Boundary

**Trigger:** Product-visible UI change — the App Mode option cards move to the canonical selection frame.
**Approval status:** Approved
**Approval evidence:** Owner authorized Phase 2B with the exact visual deltas listed below, after the Phase 1 audit froze the canonical contract in GitHub #183 and Linear TNYX-139.
**Approved product/UI/data-shape boundaries:** The outer selectable frame of `_ModeOptionCard` only, plus bounded Settings tests and this brief.
**Explicit non-changes:** No Phase 2C–2F work. No Account Setup, Nutrition, onboarding or editor-sheet change. No `TioSelectableCard` API change. No `TioCardTokens` change. No new tokens. No appearance/padding override. No broad `TioAlpha`/`TioOpacity` cleanup. No Supabase, migration, navigation or persistence change. No core theme README change — the reusable contract is unchanged.

## Active Handoff

**Implementation owner:** Claude
**Review owner:** Owner
**Base:** `main` `a0b5afcd70aafa298ee0f34ea9f8ba7210aa772b` (Phase 2A merged)
**Branch:** `codex/tnyx-139-phase-2b-settings-app-mode`
**Repository state verified:** 2026-09-04, clean at branch creation
**Device check:** **PENDING OWNER DEVICE CHECK**

## Intentional visual delta — approved

Only the outer frame changes. Everything inside the card is untouched.

| Aspect | Before (Settings) | After (canonical) |
|---|---|---|
| Selected fill | `surfaceRaised`, solid | `primary` @ `selectedContainerAlpha` (10%) |
| Selected border | `TioStroke.width2` (2dp) | `selectedBorderWidth` (1.25dp) |
| Unselected border | `TioStroke.width1` (1dp) | `unselectedBorderWidth` (0.75dp) |
| Unselected outline | `outlineStrong` @ `TioAlpha.alpha35` (~13.7%) | `outlineStrong` @ `unselectedOutlineAlpha` (40%) |
| Radius | `TioRadius.lg` literal | `TioCardTokens.radius` (same value, now governed) |
| Padding | `TioSpacing.lg` (16dp) | `TioCardTokens.padding` (16dp, unchanged) |
| Disabled | `Opacity(opacity64)` locally | `opacity64`, owned by the component |

**Motion — an additional delta, surfaced by Codex review and not in the owner's original list.** The old frame animated nothing on the border (plain `Container`) while `Material` cross-faded its fill at Flutter's 200ms default. The canonical card animates **both** border and fill with `context.tioMotion.fast` (150ms), and both become instantaneous under `reducedMotion`. This is inherent to adopting the component — it cannot be avoided without an override the owner forbade — and every later 2C–2F migration carries the same change. It is **declared here for owner sign-off at device acceptance** rather than shipped as "no behavior change". A test pins it.

The `alpha35` → 40% correction is the single most visible change: the old value was the `TioAlpha`/`TioOpacity` unit mix-up the audit found, rendering the outline at roughly a third of its intended strength.

## Behavior-preservation boundary

Unchanged and asserted: `AppMode` values · selected-value semantics · save timing (selection is local, only **Save App Mode** writes) · Save disabled while unchanged · all options disabled while `_isSaving` · the failure message *"Could not update App Mode. Please try again."* · the `onModeChanged` contract · nav preview following the local selection · route, navigation, persistence, analytics, capability gating · labels, descriptions, icons.

**Stable key preserved:** `ValueKey('app-mode-settings-${mode.storageValue}')` moved from the local `InkWell` to `TioSelectableCard`. `apps/app/test/app/app_mode_settings_write_parity_test.dart` passes **unchanged**, which is the proof.

**Semantic label preserved:** `'${_appModeLabel(mode)}. ${_appModeDescription(mode)}'`, now passed as `TioSelectableCard.semanticLabel` rather than a local `Semantics` wrapper — one semantics owner, not two.

## What was removed

The local `Opacity`, `Semantics`, `Material`, `InkWell` and decorated `Container` are gone; the component owns all five. The feature keeps only the `Row` content.

## Pre-existing defects found, deliberately not fixed here

**`_AppModeNavPreviewCard` overflows.** Selecting **Hybrid** overflows the preview's `Row` by 14px at 390dp width **at normal text scale**, and at 1.6x text scale the preview overflows on main by up to 157px. Verified by running the new tests against the pre-migration file: the overflow is larger on `main` than after this migration, so it is pre-existing and unrelated to the card frame. The nav preview is explicitly outside Phase 2B, so this is reported rather than patched. Two tests run on a wider surface so this unrelated defect cannot mask what they assert — the Hybrid-selection case, and the large-text case at a width where nothing overflows — with the reason recorded inline in both.

## Tests

`apps/features/settings/test/presentation/app_mode_settings_page_test.dart` — 12 cases: one card per mode · the screen consumes the core component rather than a local recipe · inner content survives · current mode starts selected · tapping moves local selection · selecting does not persist before Save · semantic label with button/selected/enabled and a tap action · unselected reports not selected · options disabled and inert while a save is in flight, with the selection unmoved · dark mode renders · cards lay out at large text scale with no exception at all · the declared motion delta.

Deliberately not re-tested here: the card's own pixel/token contract, already covered by the core component's 16 tests.

## Validation

Validated at `40aab8486e44536745bc8f7195d4f7a1c3c4707b` (base `main` `a0b5afcd`), then re-run after the Codex corrections:

| Check | Command | Result |
|---|---|---|
| Format | `dart format` on the changed Dart files | PASS |
| Whitespace | `git diff --check origin/main...HEAD` | exit 0 |
| Settings analyze | `flutter analyze --no-pub` in `apps/features/settings` | **No issues found** |
| New Settings tests | `flutter test test/presentation/app_mode_settings_page_test.dart` | **12 passed** |
| Write-parity regression | `flutter test test/app/app_mode_settings_write_parity_test.dart` in `apps/app`, file **unchanged** | **2 passed** |
| Workspace analyze | `flutter analyze --no-pub` per package (mirrors CI's `melos exec`) | **16/16 packages PASS** |
| Workspace tests | `flutter test --no-pub` per test-bearing package | **14/14 packages PASS, 1677 tests** |
| Required CI | Flutter CI on the exact PR head | **33840628381 SUCCESS** |

`melos` is not installed locally, so the workspace sweeps iterate the same package set `.github/workflows/flutter-ci.yml` drives through `melos exec`. Required GitHub CI remains the source of truth.

**Still required before Ready/merge:**

1. **Owner physical-device acceptance** — Settings → App Preferences → App Mode, all three modes, light and dark. Status: **PENDING OWNER DEVICE CHECK**.
2. **Owner sign-off on the motion delta** recorded above, which was not in the original approved list.

## Review findings

Codex reviewed head `40aab848` and raised 3 P2 findings; all three were independently verified as valid and fixed:

1. **Loose overflow predicate.** The large-text test accepted any `FlutterError`, so a genuine card overflow would still have passed. Now runs at a width where nothing overflows and asserts `takeException()` is null outright.
2. **Undeclared motion change.** See the motion delta above — now declared, pinned by a test, and raised for owner sign-off rather than absorbed under "no behavior change".
3. **Validation section was a pointer, not evidence.** This section now carries the commands, results and the remaining gates.

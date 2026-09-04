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

The `alpha35` → 40% correction is the single most visible change: the old value was the `TioAlpha`/`TioOpacity` unit mix-up the audit found, rendering the outline at roughly a third of its intended strength.

## Behavior-preservation boundary

Unchanged and asserted: `AppMode` values · selected-value semantics · save timing (selection is local, only **Save App Mode** writes) · Save disabled while unchanged · all options disabled while `_isSaving` · the failure message *"Could not update App Mode. Please try again."* · the `onModeChanged` contract · nav preview following the local selection · route, navigation, persistence, analytics, capability gating · labels, descriptions, icons.

**Stable key preserved:** `ValueKey('app-mode-settings-${mode.storageValue}')` moved from the local `InkWell` to `TioSelectableCard`. `apps/app/test/app/app_mode_settings_write_parity_test.dart` passes **unchanged**, which is the proof.

**Semantic label preserved:** `'${_appModeLabel(mode)}. ${_appModeDescription(mode)}'`, now passed as `TioSelectableCard.semanticLabel` rather than a local `Semantics` wrapper — one semantics owner, not two.

## What was removed

The local `Opacity`, `Semantics`, `Material`, `InkWell` and decorated `Container` are gone; the component owns all five. The feature keeps only the `Row` content.

## Pre-existing defects found, deliberately not fixed here

**`_AppModeNavPreviewCard` overflows.** Selecting **Hybrid** overflows the preview's `Row` by 14px at 390dp width **at normal text scale**, and at 1.6x text scale the preview overflows on main by up to 157px. Verified by running the new tests against the pre-migration file: the overflow is larger on `main` than after this migration, so it is pre-existing and unrelated to the card frame. The nav preview is explicitly outside Phase 2B, so this is reported rather than patched. Two tests use a wider surface to keep this unrelated defect from masking what they assert, with the reason recorded inline.

## Tests

`apps/features/settings/test/presentation/app_mode_settings_page_test.dart` — 11 cases: one card per mode · the screen consumes the core component rather than a local recipe · inner content survives · current mode starts selected · tapping moves local selection · selecting does not persist before Save · semantic label and selected/button/enabled semantics · unselected reports not selected · options disabled and inert while a save is in flight, with selection unmoved · dark mode renders · content lays out at large text scale.

Deliberately not re-tested here: the card's own pixel/token contract, already covered by the core component's 16 tests.

## Validation

Recorded in the PR body at the validated SHA.

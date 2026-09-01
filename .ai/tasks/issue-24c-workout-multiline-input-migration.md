# GitHub #24 Phase #24-C — Workout Multiline Field Migration

**Status:** Ready for review
**Primary owner:** `apps/core` reusable field components + `apps/features/onboarding` (Workout section screens)
**Affected platforms:** Flutter phone UI

## Owner Approval and Scope Boundary

**Approval status:** Approved as a bounded core-foundation + consumer-migration slice, explicitly requested by the owner as GitHub #24 Phase #24-C.
**Approved boundaries:** Migrate the three evidenced Workout notes-field consumers (Equipment, Special Event, Health Concerns) to a governed `TioInput.multiline` variant, adding only the capabilities those three consumers actually need.
**Explicit non-changes:** Nutrition Profile "Other", the inline "Other" family (Health Conditions), Settings username, Auth, mobile-number components, numeric editors, `TioEditorSheet` / #183, selection rows, Workout domain/business rules, repositories/providers, navigation/routes, Supabase, schema/migrations, new validation rules, new Workout functionality, GitHub #24 closure.

## Active Handoff

**Implementation owner:** Claude (Claude Code). Recorded before source mutation, matching the repository's disabled-AI-attribution policy (`CONTRIBUTING.md`, `.claude/settings.json`) — no `Co-Authored-By` trailer on this slice's commits.
**Branch:** `refactor/issue-24-c-workout-multiline-migration`
**Base:** `main` @ `413acdde6c0733916c91569461c66bcf360ea4c2`
**Current state:** Implemented, validated locally, ready to publish as a Draft PR.
**Validation remaining:** Exact-head repository Flutter CI, then review.

## 1. Discovery

### Fresh pre-flight verification (before any implementation)

- PR #195 / Phase #24-B: **MERGED** at `413acdde6c0733916c91569461c66bcf360ea4c2`.
- GitHub #24: **OPEN**.
- Linear TNYX-146 (#24-B): **Done**.
- `main == origin/main == 413acdde`, working tree clean, no overlapping open PR.
- One unrelated note: `main` was rewritten between #24-A and #24-B (owner-authored `chore(root): disable AI commit attribution`, force-pushed with history rebase). A `backup/pr195-before-main-history-rewrite` branch preserves the prior history. This is an owner action, not something this slice touches or needed to react to beyond respecting the new attribution policy.

### Fresh raw-field inventory (repository-wide, non-test)

20 raw `TextField`/`TextFormField` on `main` before this slice (down from 22 before #24-B, which migrated the two Nutrition numeric editors). Of the three historical Workout notes-field candidates, all three are still present verbatim:

| File | Widget | maxLines/minLines |
|---|---|---|
| `onboarding/.../workout/equipment_screen.dart:194` | `TextField` | 4 / 3 |
| `onboarding/.../workout/special_event_screen.dart:65` | `TextFormField` | 4 / 3 |
| `onboarding/.../workout/health_concerns_screen.dart:75` | `TextFormField` | 6 / 4 |

### Family boundary — verified, not assumed

All three share: 16dp rounded surface (`TioRadius.lg`), `filled: true` / `fillColor: colors.surface`, identical border construction (`colors.outlineStrong @ TioCardTokens.unselectedOutlineAlpha`, width `TioCardTokens.unselectedBorderWidth`/`selectedBorderWidth` — numerically identical to `TioInputTokens.outlineWidth`/`focusedOutlineWidth`), and `TextCapitalization.sentences`. This is one coherent family.

They are **not** identical in every property, and the migration preserves the differences exactly rather than forcing one look onto all three:

| Property | Equipment | Special Event | Health Concerns |
|---|---|---|---|
| `textStyle` base | `bodyMedium` | `bodyLarge`, size 15, height 140 | `bodyLarge`, size 15, height 140 |
| `hintStyle` alpha | `textSecondary @ 60%` | `textSecondary @ 50%` | `textSecondary @ 50%` |
| `contentPadding` | `symmetric(h: lg, v: md)` | `all(lg)` | `all(lg)` |
| `textAlignVertical` | unset | `.top` | `.top` |
| `keyboardType` | unset (→ `text`) | `.multiline` | `.multiline` |
| stable key | **none** (gap, closed below) | on wrapping `Container` | on wrapping `Container` |

Equipment's field had **zero existing test coverage** and **no stable key** before this slice — the only production caller (`workout_step_renderer.dart`) never wires `onAdditionalInfoChanged` either, so the field is currently visually present but functionally inert in the shipped app. Recorded as a finding; not fixed here (would be new Workout functionality, explicitly out of scope).

### Current `TioInput` API after #24-A/#24-B

Three variants: `standard` (14dp/52dp), `compactNumber`, `numericEditor` (dense exact-value). None reproduce the notes-field contract: radius is fixed at 14dp for every non-`numericEditor` variant, unfocused border alpha branches on light/dark theme (the raw fields use one fixed alpha regardless of theme), and there is no way to override hint style or vertical text alignment.

## 2. Core rule applied

`TioInput` could not reproduce the evidenced contract exactly, so the smallest reusable, domain-neutral addition was made: `TioInputVariant.multiline` / `TioInput.multiline`, plus three narrowly-scoped additions to the shared widget:

1. **`TioInputTokens.multilineRadius`** (`TioRadius.lg`) and **`multilineUnfocusedOutlineOpacity`** (`TioOpacity.opacity40`, fixed regardless of theme) — new tokens; the 14dp/16dp contracts remain unnormalized, per standing #24 policy.
2. **`hintStyle`** — general optional override (mirrors the existing `textStyle` override pattern). Evidenced by two *different* real alpha values (50% and 60%) across the three consumers; no single default could reproduce both.
3. **`textAlignVertical`** — general optional override. Evidenced: two consumers need `.top`, one needs Flutter's implicit default (unset).
4. **`textInputAction` widened to nullable** — the raw fields never set it, so Flutter's own implicit resolution applied (`newline` when `keyboardType` is `multiline`, `done` otherwise). `TioInput` previously always forced an explicit value; reproducing the raw fields' exact current behavior required letting `null` pass through. `standard`/`compactNumber`/`numericEditor` keep explicit non-null defaults and are unaffected.

`maxLines`/`minLines` are **required** on `.multiline` (4/3, 4/3, 6/4 across the three consumers — no sensible shared default). `textCapitalization` defaults to `.sentences` (3/3 evidence) but stays overridable. `label`/`leading`/`trailing`/`maxLength` remain normal optional params (unlike `numericEditor`'s narrower, intentionally-constrained surface) since nothing evidences a need to forbid them for a notes field.

**Not added:** anything not evidenced by these three consumers. No feature-specific variant names, no `WorkoutNotesInput`/`EquipmentInput`/`HealthConcernsInput`.

## 3. Implementation

- [x] `TioInputVariant.multiline` + `TioInput.multiline` named constructor.
- [x] `TioInputTokens.multilineRadius`, `multilineUnfocusedOutlineOpacity`.
- [x] `hintStyle`, `textAlignVertical` general overrides; `textInputAction` widened to nullable.
- [x] `standard`/`compactNumber`/`numericEditor` unaffected — regression-tested explicitly.
- [x] Equipment, Special Event, Health Concerns migrated. Raw `TextField`/`TextFormField` removed from all three.
- [x] Equipment gained a stable key (`workout-equipment-input`, new — none existed before) for consistency with the other two and to close its test-coverage gap.
- [x] Special Event / Health Concerns: key moved from the now-redundant wrapping `Container` (no other purpose — no decoration/padding) directly onto `TioInput.multiline`.
- [x] `onAdditionalInfoChanged` (nullable in `EquipmentScreen`'s own API) adapted to `TioInput`'s required non-null `onChanged` via `(value) => widget.onAdditionalInfoChanged?.call(value)` — a mechanical type adaptation, not a behavior change.
- [x] Focused core contract tests for `TioInput.multiline`.
- [x] Focused regression tests closing Equipment's prior test-coverage gap.
- [x] Existing Workout section tests preserved unmodified (all still pass unchanged).

## 4. Quality Review

### Validation Run

```text
dart format
  apps/core/lib/src/ui/components/inputs/tio_input.dart
  apps/core/lib/src/theme/tokens/components/tio_input_tokens.dart
  apps/core/test/ui/components/tio_input_test.dart
  apps/features/onboarding/lib/.../workout/equipment_screen.dart
  apps/features/onboarding/test/presentation/workout_section_test.dart
PASS

flutter analyze  # apps/core
PASS — No issues found

flutter test  # apps/core
PASS — 171 tests (was 151; +20, including the new multiline group and one
       new theme-token contract test already present from a prior slice)

flutter analyze  # apps/features/onboarding
PASS — No issues found

flutter test  # apps/features/onboarding/test/presentation/workout_section_test.dart
PASS — 9 tests (was 6; +3: two new Equipment tests, one existing suite
       unmodified)

flutter test  # apps/features/onboarding (full package)
PASS — 450 tests (was 447 pre-slice baseline; +3)

git diff --check
PASS
```

`apps/app` was not analyzed/tested: no route, composition, or key coupling exists between the app package and any of the three migrated files or their keys (verified by repository-wide grep).

### Repository raw-field audit — proof

```text
Before this slice (main):  20 raw TextField/TextFormField (non-test)
After this slice:          17

grep -rn "TextField(\|TextFormField(" apps/features/onboarding/lib/.../workout/
  → no matches (all three raw fields gone)
```

The 17 remaining are all explicitly out of scope for #24-C: 6 core-internal (the reusable implementations themselves), Auth ×3, Nutrition Profile "Other" ×1, onboarding inline "Other"/Step Target ×2, Settings ×4, and the onboarding Nutrition Profile "Other" component ×1.

### Self-review findings

- **Equipment's `onAdditionalInfoChanged` is dead in production.** `workout_step_renderer.dart` never passes it (or `additionalInfo`), so the field has always been visually present but functionally inert in the shipped flow. Not fixed here — wiring it up would be new Workout functionality. Recorded for whoever eventually owns that decision.
- **Cursor colour.** Migrating from a raw field to `TioInput` means the cursor now resolves to `context.tioColors.primary` instead of Flutter's implicit default. This is identical in nature to every other `TioInput` migration already shipped (#24-A/B) and is not a new risk specific to this slice.
- **Test-only overflow fix.** The isolated Equipment widget tests needed a `SingleChildScrollView` wrapper to avoid a `RenderFlex` overflow at the default 800×600 test viewport — `EquipmentScreen`'s image grid plus notes field don't fit unaided outside the real app's scrollable onboarding shell. This is a test-harness fix, not a product change; the existing integration-style tests that reach `EquipmentScreen` through the full `OnboardingFlowPage` never hit this because that shell is already scrollable.

## 5. Final Handoff

### Changed Files

- `apps/core/lib/src/ui/components/inputs/tio_input.dart`
- `apps/core/lib/src/theme/tokens/components/tio_input_tokens.dart`
- `apps/core/test/ui/components/tio_input_test.dart`
- `apps/core/lib/src/theme/README.md`
- `apps/features/onboarding/lib/src/presentation/screens/workout/equipment_screen.dart`
- `apps/features/onboarding/lib/src/presentation/screens/workout/special_event_screen.dart`
- `apps/features/onboarding/lib/src/presentation/screens/workout/health_concerns_screen.dart`
- `apps/features/onboarding/test/presentation/workout_section_test.dart`
- `.ai/tasks/issue-24c-workout-multiline-input-migration.md`

### Actual Behavior

All three Workout notes fields render and behave exactly as before migration — same radius, border, fill, typography, hint copy/alpha, padding, capitalization, keyboard type, vertical alignment, and controller/focus lifecycle. Equipment additionally gained a stable key and closed a pre-existing test-coverage gap.

### Known Limitations

Equipment's `additionalInfo`/`onAdditionalInfoChanged` remain unwired in production — a pre-existing gap, not introduced or fixed by this slice.

### Final Status

`READY`

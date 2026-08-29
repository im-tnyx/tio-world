# Design System Slice G — Remaining UI

**Status:** Validated  
**Current phase:** Complete  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Remaining production Flutter UI outside Slices A–F now consumes governed core design-system ownership where product-visible presentation exists. Packages without substantive production presentation were inventoried and intentionally left without fake token migrations.

## Mandatory Visual Freeze

No visible UI change was introduced. Existing layout, spacing, colors, typography, radius, icon/image sizing, motion, component geometry and platform behavior were preserved through exact-value ownership migration.

## Preconditions

- [x] Slices A–F are `Validated`.
- [x] Slice F final implementation head `da9e60d6b8a5afc1b293d59cef7a7aacce5553c4` passed Flutter CI #843.

## Completed Inventory

### Feature packages with no substantive production presentation

The following packages contain navigation/contracts/README shells but no substantive product screen/widget implementation requiring a Slice G visual migration:

- `apps/features/workout`
- `apps/features/nutrition`
- `apps/features/progress`
- `apps/features/coaching`

No fake token migration was introduced for these packages.

### Shared package

`apps/shared` contains shared contracts, device/network/result/domain code and no production presentation surface. No visual migration was required.

### App composition

`apps/app/lib/app/router.dart` contains composition/navigation wiring but no raw product visual colors or typography to migrate. `apps/app/lib/app/app.dart` uses transparent system/status navigation-bar values strictly as edge-to-edge platform chrome; those framework values remain intentionally outside product visual token ownership.

### Splash

`apps/features/splash/lib/src/presentation/screen/splash_screen.dart` was migrated in commit `0caeaadde2fd603af03cffa1075102be934a38db`.

Governed ownership now covers:

- ~~exact `120dp` brand-logo geometry via `TioSize.dp120`~~ — **superseded**: the brand-logo image was replaced with a text wordmark and `TioSize.dp120` was removed (see below);
- radius, spacing and loader geometry;
- loader color/stroke;
- failure-state typography and line height.

The `4s` initial-destination timeout remains behavior/program timing and was not converted into design-system motion.

Static ownership gate:

`apps/features/splash/test/presentation/splash_design_system_ownership_test.dart`

Validation: **Flutter CI #845** passed Flutter analyze, Dart analyze, Flutter tests and Dart tests.

**Update (PR #171):** the splash logo image was replaced with a bold "TIO" text wordmark; `TioSize.dp120` existed only for that image's geometry and, once orphaned, was removed from `apps/core`'s primitive registry per its own "evidenced by current production UI" policy (enforced by `apps/core/test/theme/final_enforcement_primitive_liveness_test.dart`). See [`splash-tio-wordmark.md`](splash-tio-wordmark.md) for the current governed splash ownership and validation evidence; this slice's own outcome (migrating splash off raw literals onto governed tokens) remains valid and superseded only for the specific `dp120` geometry line above.

### Wear

Wear Home presentation was migrated in commit `1a031d76ab7155e2879320437dff448031cf6b0c`.

Governed ownership now covers:

- pure-black scaffold ownership;
- exact existing Wear tile colors through `TioPalette.gray022` (`0xFF161616`) and `TioPalette.gray036` (`0xFF242424`);
- exact one-off radii through physical `TioSize` ownership rather than forcing semantic normalization;
- tile/icon geometry and spacing;
- typography weight overrides.

Static ownership gate:

`apps/wear/test/wear_design_system_ownership_test.dart`

Validation: **Flutter CI #846** passed Flutter analyze, Dart analyze, Flutter tests and Dart tests.

## Hard Boundaries Preserved

- [x] no workout/nutrition/progress business-rule changes;
- [x] no domain calculation changes;
- [x] no persistence/Supabase changes;
- [x] no navigation behavior changes unrelated to styling;
- [x] no feature token catalogs introduced;
- [x] platform-specific system-bar behavior preserved.

## Checklist

- [x] Build a remaining-package inventory before edits.
- [x] Process one package or bounded UI surface at a time.
- [x] Classify all fixed visual values before migration.
- [x] Reuse governed core primitives/roles/components first.
- [x] Apply `.ai/tasks/design-system-hardcoded-color-audit.md`.
- [x] Remove or avoid feature-owned visual/token catalogs.
- [x] Preserve platform-specific behavior where intentional.
- [x] Run focused package tests/static audit after each bounded migration.
- [x] Run analyze and required CI at package/slice boundaries.

## Completion Lifecycle

- [x] Inventory
- [x] Classification
- [x] Planned ownership
- [x] Implementation
- [x] Focused tests
- [x] Static audit
- [x] Pixel/UI regression contract preserved by exact-value migration and visual freeze
- [x] Analyze
- [x] Required CI
- [x] Update evidence
- [x] Mark `Validated`
- [x] Unblock Slice H

## Exit Criteria

- [x] all remaining production UI consumes governed core visual ownership where production visuals exist;
- [x] no feature-owned design-token catalogs were introduced or remain in Slice G migrated scope;
- [x] no unapproved visible UI changes occurred;
- [x] tests/analyze/required CI pass.

## Handoff

Slice G is `Validated`. Slice H — Final Enforcement is unblocked and may begin repository-wide compatibility/static ownership enforcement.
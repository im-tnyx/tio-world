# TNYX-139 Phase 2A — TioSelectableCard foundation

**Status:** In progress
**Primary owner:** Flutter mobile / Core design system
**Affected platforms:** Flutter Android and iOS (core package only)

## Owner Approval and Scope Boundary

**Trigger:** None — this slice adds a reusable core component with zero production consumers, so it changes no product-visible UI.
**Approval status:** Approved
**Approval evidence:** Phase 1 audit frozen in GitHub #183 and Linear TNYX-139. Owner froze the direction: a separate `TioSelectableCard`, canonical appearance from the existing `TioCardTokens` contract, canonical unselected outline 40%.
**Approved product/UI/data-shape boundaries:** One new core component, its public export, focused core tests, and the theme README contract entry. No feature package is touched.
**Explicit non-changes:** No production selection-card surface migrated. No editor-sheet work. No `TioAlpha`/`TioOpacity` rename. No `AGENTS.md` pointer fix. No Supabase migration, schema, RLS, or RPC change. No visual redesign.

## Active Handoff

**Planning owner:** Owner
**Implementation owner:** Claude
**Review owner:** Owner
**Implementation ownership state:** Active
**Repository state last verified:** 2026-09-04
**Branch:** `codex/tnyx-139-tio-selectable-card-foundation`
**Base:** `main` `b8b71e370500f4b1dfbc8711f580eb198ddd61d6`
**Observed working-tree state:** Clean at branch creation
**PR / tracker:** GitHub #183, Linear TNYX-139
**Current implementation state:** Component, export, tests, and README contract complete
**Next exact action:** Owner review, then Phase 2B (Settings App Mode migration)

## Why this exists

The Phase 1 audit found **14 production selection-card surfaces**. `TioCardTokens` already defined the selection contract, yet the same role rendered at four different strengths — 40% (6 surfaces), 35% (5), ~15.7% (2), ~13.7% (1) — because every surface hand-wrote its own `BoxDecoration`. Tokens describe the contract; nothing enforced it.

`apps/core/lib/src/theme/README.md` had already recorded the intended shape, in its `TioGroupCard` entry: *"selection cards remain a separate component contract."*

## Decisions

**Separate component, not a `TioCard` flag.** `TioCard`'s `variant` axis is about fill and elevation. Selection is orthogonal state, so folding it in would require defining every variant x selected combination for a single recipe that is actually needed.

**No `TioSelectableCardTokens`.** The theme README's component-token admission gate is not met: `TioCardTokens` already expresses every value this component needs, and a second family would be a duplicate physical registry. The component consumes the existing tokens directly.

**No appearance overrides in the API.** Radius, padding, border widths, fill and outline strength are fixed. An override parameter is exactly how the current drift became representable.

**`enabled` is admitted from evidence, not speculation.** `settings/app_mode_settings_page.dart` today wraps its card in `Opacity(TioOpacity.opacity64)` and suppresses the tap when a mode is unavailable. Phase 2B must preserve that capability gating, so the component owns it. `TioOpacity.opacity64` is carried over unchanged.

**Motion follows the dominant audited convention.** Ten onboarding surfaces animate the decoration with `TioDuration.ms150`; the component uses `context.tioMotion.fast`, the governed runtime role for that value, so reduced-motion resolution applies.

**Single semantics node.** The ink well is excluded from semantics and the wrapping `Semantics` owns button/selected/enabled plus the tap action, so an option is announced once rather than twice.

## Known gap, deliberately not closed here

`_NutritionChoiceTile` and `_ThemeOptionCard` currently use `EdgeInsets.symmetric(horizontal: TioSpacing.lg, vertical: TioSize.dp14)`, while the canonical padding is `EdgeInsets.all(TioCardTokens.padding)` (16). No padding override was added, because the owner froze canonical padding and an override would re-open the drift.

**Consequence for Phase 2D:** migrating those two surfaces changes their vertical padding 14 → 16. That is a 2dp visual delta on two surfaces and must be declared in that slice, not absorbed silently. If the owner decides those surfaces must keep 14, that is a documented gap to revisit before 2D — not something this slice pre-authorizes.

## Scope

**In scope:** `apps/core/lib/src/ui/components/cards/tio_selectable_card.dart`, the `cards.dart` barrel export, `apps/core/test/ui/components/tio_selectable_card_test.dart`, and the theme README contract entry.

**Out of scope:** every production consumer. Phase 2B–2F migrate them.

## Validation

Recorded in the PR body and the final report at the validated SHA. Because this changes a public core export, package-focused checks alone are not treated as sufficient.

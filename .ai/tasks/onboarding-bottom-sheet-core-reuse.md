# Onboarding Core Bottom-Sheet Reuse

**Status:** Recovered (Phase 3C)
**Primary owner:** `apps/core` + `apps/features/onboarding` + `apps/features/account_setup`
**Affected platforms:** Flutter Android and iOS

## 1. Discovery

### User Outcome

Every modal presented by Product Onboarding should consume a reusable core UI
sheet contract instead of owning its own bottom-sheet surface.

### Success Criteria

- informational onboarding sheets use one core presenter and surface;
- the onboarding exit confirmation uses a core confirmation-sheet presenter;
- Mobile Account Setup uses the same core information-sheet presenter;
- specialized height, weight, and date picker sheets remain their existing core-owned components;
- product copy, callbacks, and domain decisions remain feature-owned.

### Scope

- reusable `showTioInformationBottomSheet` and `showTioConfirmationBottomSheet` core presenters in `apps/core`;
- migrate all `showOnboardingDataCollectionSheet` call sites in Product Onboarding to `showTioInformationBottomSheet`;
- migrate exit confirmation to `showTioConfirmationBottomSheet`;
- migrate GoalPace info and attention sheets to `showTioInformationBottomSheet`;
- delete `onboarding_data_collection_sheet.dart` (replaced by core presenter);
- migrate Account Setup Mobile to `showTioInformationBottomSheet`;
- focused core and feature regressions.

### Non-Goals

- no new feature-owned modal surfaces;
- no redesign of any screen or nav flow;
- no attachment cleanup;
- no worktree creation.

## 2. Codebase Exploration

### Verified Evidence

- `onboarding_data_collection_sheet.dart` deleted; `widgets.dart` export removed.
- `onboarding_flow_page.dart`: four call sites replaced with core presenters.
- `goal_pace_screen.dart`: `_showGoalPaceInfoSheet` and `_showAttentionSheet` replaced; Phase 3A Units changes retained.
- Historical provenance: `5779ec854ed893154da4b8aeac38de44897210c4`.
- Phase 3C recovery branch: `codex/github-stack-consolidation`.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Delete local generic sheet | Approved | Core presenter supersedes it |
| Preserve Phase 3A Units in GoalPace | Required | UnitConverters/_formatPace must survive |
| Onboarding copy/nav stays feature-owned | Required | Core owns only the modal shell |

## 4. Architecture Design

Core owns modal shell, safe-area, semantic styling, close/actions. Features own copy, navigation, state, and persistence.

## 5. Implementation Plan

- [x] Core presenters created and exported.
- [x] Onboarding call sites migrated.
- [x] GoalPace info + attention sheets migrated; Units preserved.
- [x] `onboarding_data_collection_sheet.dart` deleted.
- [x] Regression test updated with `TioInformationBottomSheet` type assertion.
- [ ] Validation pending Phase 3C commit gate.

## 6. Quality Review

Pending Phase 3C full validation run.

## 7. Final Handoff

**Current status:** RECOVERED — implementation complete; validation pending Phase 3C gate.

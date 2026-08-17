# Nutrition Screen

**Surface:** Phone primary tab for `nutrition` and `hybrid` modes
**Current route:** `/nutrition`
**Primary owner:** `apps/features/nutrition`
**Status:** Current route is a shared placeholder. The sections below are the target contract.

## Purpose

Help the user track meals and water against clear daily targets without turning the app shell into a nutrition engine. Nutrition owns targets, diary behavior, calculations, and later Meal Plan flows.

## Target Content

The root app bar shows a non-interactive Meal Log streak status on the right. It
shows only the icon until real diary history provides a positive count; it never
fabricates a number or routes to Progress.

1. **Today’s target summary** — calories, macros, and any explicitly chosen nutrition goal, with an understandable remaining/consumed presentation. It opens [Nutrition Targets](nutrition-targets.md).
2. **Meal diary** — grouped meal entries with add, edit, remove, and detail actions after the diary MVP is implemented. See [Meal Diary](meal-diary.md).
3. **Quick actions** — add food, add a meal, and add water. Use phone flows for full search and editing.
4. **Nutrition Targets** — goal, dietary preference, target inputs, and explicit overrides. Profile context may provide a starting point; Nutrition owns the calculation, validation, and final user choice. See [Nutrition Targets](nutrition-targets.md).
5. **Meal Plan** — future route after the first nutrition diary MVP. It may create, schedule, and reuse plans and later become a promoted custom shortcut, but it is not a guided default tab. See [Meal Plan](meal-plan.md).

## Key Actions And Navigation

- Food, meal, and water actions open Nutrition-owned flows.
- Target summary opens Nutrition Targets.
- Meal Plan is hidden until its approved post-MVP slice exists.
- A relevant Home card launches Nutrition without duplicating the diary in Home.
- The guided Nutrition tab is not visible in `workout` mode. Future custom navigation cannot expose Nutrition or Meal Plan there without a deliberate switch to Hybrid.

## Adaptive Entry Behavior

- When Nutrition is directly selected, Log Meal/Add Food and Add Water are primary Nutrition-owned actions.
- When Meal Plan is promoted, Nutrition may compact duplicate plan navigation while retaining today's diary and target summaries.
- When Nutrition is eligible but not directly selected in a future custom layout, Home provides a prominent Log Meal/Add Water entry and an all-features path remains available.
- Home, Nutrition, Meal Diary, and Meal Plan launch one canonical Nutrition meal-log workflow. Entry context may preselect meal period or a planned meal; save, validation, and totals stay Nutrition-owned.

## Data And State Boundaries

- Nutrition uses profile context only via a stable contract and does not read Profile widgets or state directly.
- Target defaults must be visibly distinct from user-confirmed overrides. An updated profile may suggest recalculation, never silently replace an override.
- With no diary data, show the first food/meal action and explain the target setup state.
- Before remote sync exists, saved versus pending local entries must be clear. Loading, empty, validation error, deletion confirmation, failed save, and offline states are required.
- Do not show a full food search, diary editor, or Meal Plan editor on Wear OS. Wear can initiate only approved quick actions.
- If meal/food images are approved later, files belong in the private `nutrition` Storage bucket through Nutrition; diary entries and targets remain structured data.

## Acceptance Criteria

- Nutrition is available only in `nutrition` and `hybrid` modes.
- Targets are owned and validated by Nutrition, while Profile remains the source of personal-context inputs.
- Meal Plan is a later Nutrition route and not an implied current feature; custom promotion is allowed only after implementation.
- Root-Nutrition, promoted-Meal-Plan, and hidden-but-eligible layouts reuse the same Nutrition controllers and data rules.
- Diary totals and macro indicators have text equivalents and do not rely only on colour.

## Related

- [Screen catalog](README.md)
- [Profile](profile.md)
- [Wear Home](wear-home.md)
- [Roadmap](../ROADMAP.md)
- [Adaptive navigation and action entry](../../.ai/tasks/adaptive-navigation-and-actions.md)

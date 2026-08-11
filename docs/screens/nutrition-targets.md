# Nutrition Targets Screen

**Surface:** Nested Phone Nutrition configuration
**Route:** No route exists yet
**Primary owner:** `apps/features/nutrition`
**Status:** Planned only.

## Purpose

Let the user review, accept, or override daily nutrition targets. Profile context can offer starting inputs, but Nutrition owns the calculation, validation, and final target state.

## Target Content

- Current calorie and macro targets with plain-language explanations.
- Nutrition goal and approved dietary-preference inputs.
- Profile-context inputs used for a suggested target, clearly labelled as suggestions.
- Explicit user overrides and a confirm/reset-to-suggestion action.

## Data And Rules

- Profile does not calculate or persist Nutrition-owned target overrides.
- A profile update may trigger a suggestion; it must never silently replace a confirmed target.
- Validation, explanation for missing inputs, save/error, offline/pending state, and confirmation before discarding overrides are required.
- Do not make medical, diagnostic, or unsupported dietary claims.

## Acceptance Criteria

- The user can distinguish suggested values from their confirmed overrides.
- Settings launches this module-owned screen rather than replicating its form.
- Any daily summary and Meal Diary use the same confirmed target contract.

## Related

- [Nutrition](nutrition.md)
- [Meal Diary](meal-diary.md)
- [Profile](profile.md)
- [Settings](settings.md)

# Progress Screen

**Surface:** Phone primary tab in every App Mode
**Current route:** `/progress`
**Primary owner:** `apps/features/progress`
**Status:** Current route is a shared placeholder. The sections below are the target contract.

## Purpose

Show the user meaningful change over time without owning the source workout, nutrition, profile, or recovery calculations.

## Target Content

- Goal progress and a concise period summary.
- Weight and body-measurement trends when the user has recorded them.
- Progress photos with explicit privacy-aware controls when that slice is approved.
- Workout consistency, nutrition adherence, streaks, and achievements as summaries from their owning domains.
- Date-range selection and a clear no-history state.

Recovery information may appear as a labelled summary only after Recovery has an approved contract. It must link to the Recovery flow and must not be inferred from unsupported data.

## Key Actions And Navigation

- Add or edit a Progress-owned measurement or photo through Progress flows.
- Drill into a trend or streak through Progress-owned details.
- Launch Workout or Nutrition only through public navigation contracts; do not embed their private UI.
- The guided Progress tab remains visible for all three App Modes. A future custom layout may remove direct placement only if Progress remains reachable through Home, You, or an all-features entry.

## Data And State Boundaries

- Progress consumes approved summaries, not feature presentation state or raw backend table shapes.
- When Progress photos are approved, image files belong in the private Supabase `progress` bucket through Progress; measurements, trends, and achievements remain structured feature data.
- Empty history explains which first action creates data and points to the correct feature.
- Charts require accessible values, date labels, comparison text, and a non-visual alternative.
- Data loading, error, no-permission, image-upload failure, and offline/stale states must be explicit once those capabilities are introduced.

## Acceptance Criteria

- Each indicator identifies its source and date range.
- No metric is shown as current when it is stale, unavailable, or derived from missing data.
- Photos and health-related measurements remain protected by the repository privacy rules.

## Related

- [Screen catalog](README.md)
- [Workout](workout.md)
- [Nutrition](nutrition.md)
- [Recovery](recovery.md)

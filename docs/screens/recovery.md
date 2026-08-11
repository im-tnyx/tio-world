# Recovery Screen

**Surface:** Future phone feature; not a current primary tab
**Route:** No route exists yet
**Primary owner:** future `apps/features/recovery`
**Status:** Planned only. Do not create an empty package or imply health-data support before its first approved vertical slice.

## Purpose

Give the user an honest view of rest, readiness, and training recovery when approved data supports it. Recovery is a separate product area so that its data rules, calculations, and health sensitivity do not leak into Home, Workout, or Coach.

## Proposed Entry Points

- A compact Home summary when a useful approved recovery signal exists.
- Workout muscle-map or training-calendar context when the relationship is defined.
- Progress or Coach links after their relevant contracts exist.

Recovery does not add a bottom tab to the documented App Mode navigation.

## Required Decision Before Implementation

Choose the first trustworthy source and scope before creating source code:

| Decision | Options that need explicit approval |
| :--- | :--- |
| Initial signal | Manual check-in only, or approved connected health/wearable data. |
| User outcome | Rest guidance, training-load context, sleep summary, or another narrow first slice. |
| Privacy and sync | Local-only first, or an approved account/backend contract with clear consent and retention rules. |
| Medical boundary | Non-medical wellness guidance only; no diagnosis or unsupported claims. |

## Target Content After Approval

- A dated, explainable readiness/recovery summary.
- The exact signals used, their freshness, and unavailable-data state.
- A safe next action: rest guidance, a lighter training suggestion, or link to the relevant Workout flow.
- History only after the first summary has a stable data model.

## Data And State Boundaries

- Recovery owns its domain calculation and presentation.
- It reads profile, workout, nutrition, and health summaries through explicit contracts only.
- Home, Workout, Progress, and Coach may show a small prepared Recovery summary; none calculate recovery locally.
- Permissions, consent withdrawal, no wearable data, stale data, offline data, and calculation failures must be first-class states.

## Acceptance Criteria

- The first release has one approved, understandable data source and a documented non-medical boundary.
- Every displayed recovery value tells the user when it was produced and what it means.
- No Recovery package, route, permission, or health integration is introduced before the decision table is resolved.

## Related

- [Screen catalog](README.md)
- [Workout](workout.md)
- [Progress](progress.md)
- [Feature Development workflow](../../.ai/FEATURE_DEVELOPMENT.md)

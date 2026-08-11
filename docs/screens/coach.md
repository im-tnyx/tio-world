# Coach Screen

**Surface:** Future phone primary tab in Phase 7
**Current route:** `/coach`
**Primary owner:** `apps/features/coaching`; future protected runtime in `backend/ai-coach` when introduced
**Status:** Current route is a shared placeholder. The current fixed Tio/AI tab is runtime scaffolding and conflicts with the product target; Coach is not a primary tab before Phase 7.

## Purpose

Offer contextual wellness and training guidance without putting AI orchestration, model prompts, credentials, or private-data access decisions in the mobile UI.

## Phase Gate

Do not promote Coach to a primary tab until Phase 7 begins and its input, response, safety, and server boundaries are approved. In the Phase 7 guided layout, Coach is added to every App Mode after the core mode-specific tabs:

| App Mode | Phase 7 primary tabs |
| :--- | :--- |
| `workout` | Home, Workout, Progress, Coach |
| `nutrition` | Home, Nutrition, Progress, Coach |
| `hybrid` | Home, Workout, Nutrition, Progress, Coach |

After the Phase 9 custom-navigation upgrade, Coach remains an eligible root destination but the user may choose its placement within the valid three-to-six layout. Hiding it from direct navigation must not imply that AI is active elsewhere or move coaching logic into Home.

## Target Content After The Phase Gate

- A concise current-context summary, with the source and freshness of any workout, nutrition, progress, or recovery input.
- A user prompt/action area and clearly scoped suggested actions.
- Safe links into the owning feature rather than inline editing of workouts, meals, targets, or profile data.
- Response confidence, limitations, and a non-medical boundary when health-related guidance is present.

## Data And State Boundaries

- Coaching reads prepared, approved summaries via contracts; it does not access another feature's presentation state or raw database tables.
- Mobile UI sends only approved client-safe input to the protected server contract when that service exists.
- No model secret, service-role key, hidden prompt, or privileged operation belongs in `apps/features/coaching`.
- Loading, streaming or pending response, unavailable context, network failure, unsafe request, and offline behavior must be explicit.

## Acceptance Criteria

- Before Phase 7, no primary navigation or product copy claims a live Coach experience.
- Enabled guidance names its data basis and cannot silently act on the user's behalf.
- Coach links preserve the ownership of Workout, Nutrition, Progress, Recovery, and Profile.

## Related

- [Screen catalog](README.md)
- [Recovery](recovery.md)
- [Roadmap: Phase 7](../ROADMAP.md#phase-7-ai-coach)

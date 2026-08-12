# Onboarding Screen

**Surface:** Phone full-screen setup flow
**Current route:** `/onboarding`
**Primary owner:** `apps/features/onboarding`
**Status:** App Mode selection is active through a reusable first-child section. The fixed parent-shell infrastructure and flow planner are implemented and tested but not routed; later mode-conditional child steps remain planned.

## Purpose

Collect only the minimum context required to give a user the correct product experience. The first screen selects App Mode; every later step is conditional on that selection.

## Current Implemented Boundary

- The route presents the reusable `AppModeStep` intro and all three mode cards, plus validation, saving state, and persistence errors.
- A confirmed selection is saved through the shared preference boundary and opens Home with the matching guided navigation.
- The page previews which setup branch comes next, but it does not yet collect profile, Workout, or Nutrition inputs and does not represent completed onboarding.
- The current route does not yet distinguish a draft mode choice from completed onboarding.

## App Mode Intro Section

The first parent-flow child is one combined intro and selection section, not a
separate intro screen:

1. Explain that App Mode shapes onboarding and guided navigation and remains
   changeable later in Settings.
2. Present `workout`, `nutrition`, and `hybrid` as accessible selectable cards.
3. Preview the next setup focus after selection.
4. Keep Continue disabled until a mode is selected.
5. Update only `OnboardingDraft`; derive the later child path and progress total
   from that draft.

The existing standalone route reuses this section during the compatibility period.
It will stop confirming the mode immediately only when explicit completion gating
and the approved legacy migration are wired.

## Target Parent Layout

The target flow keeps one full-screen parent at `/onboarding`. The App Mode chooser
uses no top bar and is excluded from progress. After it, top Back/progress and the
bottom primary action remain visible while only the middle child content changes.
System Back remains available on the chooser and follows the approved safe-exit
path.

```text
┌──────────────────────────────────────┐
│ Back                         Step 2/6 │
│ ━━━━━━━━━━━━━ progress ━━━━━━━━━━━━ │
├──────────────────────────────────────┤
│                                      │
│      current child step content      │
│      scrolls when needed             │
│                                      │
├──────────────────────────────────────┤
│                           Continue    │
└──────────────────────────────────────┘
```

The parent owns `Scaffold`, `SafeArea`, keyboard resize, system Back, progress,
loading, retry, and exit confirmation. `OnboardingTopBar` and
`OnboardingBottomBar` stay outside the scrolling `OnboardingContentHost`.

Each child renders one stable `OnboardingStepId`, emits typed values to one
Riverpod controller, and uses the parent's primary action. Child widgets do not
navigate, persist, call Supabase, or calculate feature targets.

## Target Step Order

The detailed target child plans are:

| App Mode | Ordered child steps |
| :--- | :--- |
| `workout` | App Mode, Profile Basics, Workout Intro, Workout Preferences, Targets, Review |
| `nutrition` | App Mode, Profile Basics, Nutrition Intro, Nutrition Preferences, Targets, Review |
| `hybrid` | App Mode, Profile Basics, Workout Intro, Workout Preferences, Nutrition Intro, Nutrition Preferences, Targets, Review |

The following five items remain the product-level macro order:

1. **App Mode selection** — `workout`, `nutrition`, or `hybrid`. Explain what each mode includes and let the user continue only after one choice.
2. **Common profile context** — only the personal and fitness information required by the selected MVP flows, with clear optional versus required fields.
3. **Workout branch** — shown for `workout` and `hybrid`; capture approved training goal, experience, equipment, and schedule defaults.
4. **Nutrition branch** — shown for `nutrition` and `hybrid`; capture approved nutrition-goal and preference inputs needed to propose targets.
5. **Review and finish** — make chosen mode and changeable defaults visible; then route to Home with the selected mode's guided navigation.

The exact personal-data fields, consent wording, and persistence method require the relevant approved task. Do not collect health data merely because a future module may use it.

## Navigation And Editing Rules

- Back retains entered values within the in-progress flow where safe.
- A user may change App Mode before finishing; no irrelevant branch data is required to complete.
- `/onboarding` remains one `go_router` route; child steps are controller state, not route paths.
- Selecting App Mode updates `OnboardingDraft`; only successful final completion publishes the confirmed mode and opens Home.
- Progress derives its position and total from the mode-specific flow plan, announces both position and title, and does not rely on color alone.
- The fixed primary action uses `Continue`, `Review`, or `Finish`; it stays reachable above the keyboard and blocks duplicate taps while saving.
- System Back follows the same transition rules as visible Back. Exiting with unsaved work requires a clear decision.
- After completion, Settings changes mode and launches module-owned target/settings flows. It must not recreate a second onboarding implementation.
- If mode change would make stored feature data unavailable from navigation, preserve the data and explain the navigation change; do not delete it silently.

## Data And State Boundaries

- `AppMode` belongs in `apps/shared`; an unfinished draft choice remains separate from the confirmed product mode and `OnboardingStatus`.
- Profile owns profile context. Workout and Nutrition own their domain defaults, calculations, and validation.
- Form validation, partial progress, interruption, persistence error, and offline behavior are required before the flow is complete.
- Plain `SharedPreferences` must not store sensitive body or health answers. Auth ordering, encrypted local storage, retention, versioning, Supabase/RLS, and account-switch behavior require approval before persistent drafts are added.

## Acceptance Criteria

- App Mode is visibly the first user decision.
- The App Mode chooser remains unnumbered with no top chrome; later Back/progress
  and the bottom primary action remain fixed while only child content changes.
- `workout`, `nutrition`, and `hybrid` show only the relevant later steps.
- Hybrid reuses common Profile input and does not duplicate it.
- Back, resume, retry, keyboard, and system Back behavior cannot silently discard entered data.
- Incomplete onboarding cannot open Home merely because a draft mode exists.
- Completion produces the documented guided mode navigation and a valid Home destination. Phase 9 custom tab personalization remains a later Settings flow.
- All sensitive inputs have purpose, editability, and privacy treatment defined before collection.

## Related

- [Onboarding flow architecture](../ONBOARDING_ARCHITECTURE.md)
- [ADR-0006: Single-Route Onboarding Parent Flow](../adr/0006-single-route-onboarding-parent-flow.md)
- [Onboarding implementation task](../../.ai/tasks/onboarding-flow.md)
- [Settings](settings.md)
- [Profile](profile.md)
- [Screen catalog](README.md)
- [App Mode foundation](../../.ai/tasks/app-mode-foundation.md)

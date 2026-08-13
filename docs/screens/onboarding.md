# Onboarding Screen

**Surface:** Phone full-screen setup flow
**Current route:** `/onboarding`
**Primary owner:** `apps/features/onboarding`
**Status:** App Mode selection, the typed nine-screen common Profile section,
and the real Hybrid-only Workout Intro gate are active in the fixed
`/onboarding` parent. Later Workout Preferences, Nutrition, Targets, Review,
persistence, and explicit completion-status slices remain planned.

## Purpose

Collect only the minimum context required to give a user the correct product experience. The first screen selects App Mode; every later step is conditional on that selection.

## Current Implemented Boundary

- The routed flow presents canonical `AppModeScreen` through `AppModeSection` with
  all three mode cards as the first child.
- The first choice stays in draft state until Finish. Finish saves through the shared preference boundary, publishes the confirmed mode, and opens Home with the matching guided navigation.
- The flow collects common Profile answers into an in-memory grouped draft. It
  does not yet collect real Workout or Nutrition inputs and does not represent
  completed onboarding.
- The current route keeps draft mode separate from completed onboarding, but explicit completion-status persistence and later owner-field slices remain planned.
- `OnboardingContentHost` defaults to `OnboardingSectionRenderer`. Every active
  step definition carries typed section metadata, and current section is derived
  from the current stable step. The optional builder remains a test seam.
- Workout Intro is now a real Hybrid-only gate. Workout Preferences, Nutrition,
  Targets, and Review owner screens are still absent and render through an
  explicitly labeled compatibility section/screen; this is not a
  production-complete flow.
- `ProfileSection -> ProfileStepRenderer` dispatches Name, Gender, Goal, Age,
  Height, Current Weight, Target Weight, Activity, and Health Conditions screens.
  `OnboardingController` owns their validation and internal navigation.

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

The routed parent flow reuses this section as the first child.
It keeps selection in draft until Finish instead of confirming immediately.

## Common Profile Section

The Profile macro step uses one typed child order:

```text
Name -> Gender -> Goal -> Age -> Height -> Current Weight
     -> Target Weight -> Activity -> Health Conditions
```

Every screen uses the shared parent Continue action and reports accessible
`Profile step N of 9` position through its screen header without a second visible
progress bar. Back moves within the child order before
returning from Name to App Mode. Common answers survive an unfinished mode change.
The final child advances directly to Workout Preferences for Workout, to Workout
Intro for Hybrid, and to Nutrition Intro for Nutrition. Workout Intro only asks
whether the Hybrid user wants to configure workout details now or later; actual
workout answers belong to the Workout section.

Validation uses verified reference bounds: name ≥ 3 trimmed characters, DOB from
1950 through today, height 100–250 cm, and weights 30–200 kg. One primary goal and
one activity level are required. Health Conditions is optional, but Other needs
a description.

These values are in-memory only. This slice adds no sensitive-data persistence,
Auth, Supabase, backend, remote sync, or Profile storage.

## Target Parent Layout

The routed flow keeps one full-screen parent at `/onboarding`. One fixed-height
compact top row exists from App Mode onward. App Mode shows Back but hides the
progress bar because it is a gate; later steps show Back on the left and one
progress bar on the right. The row has no title or step text. Retaining its height
keeps every screen title at the same vertical position. The bottom primary action
remains visible while only the middle child
content changes.
System Back remains available on the chooser and follows the approved safe-exit
path.

```text
┌──────────────────────────────────────┐
│ Back   ━━━━━━━━━━━ progress ━━━━━━━ │
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
Child changes use the Android-reference fade-through while the shell stays
fixed, so advancing feels like one continuous flow rather than a new page.
Reduced-motion settings remove this transition.

Each child renders one stable `OnboardingStepId`, emits typed values to one
Riverpod controller, and uses the parent's primary action. Child widgets do not
navigate, persist, call Supabase, or calculate feature targets.

## Current Content Hierarchy

The runtime uses one changing-content hierarchy without turning individual
screens into routes:

```text
OnboardingContentHost
  -> OnboardingSectionRenderer
     -> section widget
        -> individual step screen
```

The renderer selects a section only. It does not own flow planning, validation,
persistence, target calculation, or navigation. `BuildOnboardingFlowUseCase`
continues to produce the ordered plan, while `OnboardingController` coordinates
draft state and transitions.

## Target Step Order

The detailed target child plans are:

| App Mode | Ordered child steps |
| :--- | :--- |
| `workout` | App Mode, Profile Basics, Workout Preferences, Targets, Review |
| `nutrition` | App Mode, Profile Basics, Nutrition Intro, Nutrition Preferences, Targets, Review |
| `hybrid` | App Mode, Profile Basics, Workout Intro, Workout Preferences, Nutrition Intro, Nutrition Preferences, Targets, Review |

The following five items remain the product-level macro order:

1. **App Mode selection** — `workout`, `nutrition`, or `hybrid`. Explain what each mode includes and let the user continue only after one choice.
2. **Common profile context** — only the personal and fitness information required by the selected MVP flows, with clear optional versus required fields.
3. **Workout branch** — shown for `workout` and `hybrid`; capture approved training goal, experience, equipment, and schedule defaults.
4. **Nutrition branch** — shown for `nutrition` and `hybrid`; capture approved nutrition-goal and preference inputs needed to propose targets.
5. **Review and finish** — make chosen mode and changeable defaults visible; then route to Home with the selected mode's guided navigation.

The current personal-data fields and in-memory purpose copy are implemented in the
common Profile section. Durable ownership, final consent wording, and any
persistence method still require an approved Profile/privacy task. Do not expand
health collection merely because a future module may use it.

## Navigation And Editing Rules

- Back retains entered values within the in-progress flow where safe.
- A user may change App Mode before finishing; no irrelevant branch data is required to complete.
- `/onboarding` remains one `go_router` route; child steps are controller state, not route paths.
- Selecting App Mode updates `OnboardingDraft`; only successful final completion publishes the confirmed mode and opens Home.
- Progress derives its position and total from the mode-specific flow plan, announces both position and title, and does not rely on color alone.
- App Mode, Profile, and compatibility children reuse the shared theme-backed
  screen-header hierarchy. Text-entry validation errors remain associated with
  their owning `TioInput`.
- Interactive card outlines meet non-text contrast in light, dark, and OLED
  themes; fade-through and progress timings come from semantic motion tokens.
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
- The App Mode chooser remains unnumbered with Back-only chrome and hidden
  progress; later Back/progress and the bottom primary action remain fixed while
  only child content changes.
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

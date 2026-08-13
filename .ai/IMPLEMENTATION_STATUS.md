# Implementation Status

Use this file to distinguish the product plan from shipped behavior. Verify source before relying on any row during implementation or review.

## Status Terms

- **Documented**: direction exists in canonical docs only.
- **Scaffolded**: package, route, or UI exists, but the end-to-end behavior is incomplete.
- **Implemented**: source contains the intended behavior; it may still need validation.
- **Validated**: applicable automated or manual checks have been recorded for the implemented slice.

| Capability | Status | Owner | Evidence and next boundary |
|---|---|---|---|
| Flutter phone shell | Implemented | `apps/app`, `apps/core` | `go_router` and `StatefulShellRoute.indexedStack` keep stable registered branches; visible guided tabs are derived from App Mode. Bottom navigation appears only on exact roots. Home renders uppercase `TIO`, centered plan status, and Profile without Back/Settings/streak. Workout and Nutrition roots render non-interactive owner-specific streak status. |
| App Mode contract | Validated | `apps/shared` | Pure-Dart `AppMode`, `AppDestination`, guided mappings, and `AppModePreference` exist and are covered by focused tests. |
| Supabase foundation | Documented | future `supabase/` | Supabase Auth, Postgres/RLS, and private module Storage are planned. No workspace, project, client, migration, bucket, or credential exists. |
| Gemini integration | Documented | future protected function/backend | Future server-only option for approved AI slices; no provider key, client, or runtime exists. |
| Mode selection and persistence | Implemented | onboarding, Settings, `apps/shared`, `apps/app` | First-screen selection and Settings editing share one controller and `SharedPreferencesAsync` adapter. Missing/invalid data returns to selection. Device restart behavior still needs manual device verification; later onboarding steps are pending. |
| Full onboarding parent flow | Scaffolded | `apps/features/onboarding` with Profile, Workout, Nutrition, `apps/shared`, and `apps/app` contracts | Typed macro sections, exact mode plans, stable-step reconciliation, fixed parent shell, `AppModeSection -> AppModeScreen`, `ProfileSection -> ProfileStepRenderer` with nine typed in-memory child screens, and the real Hybrid-only `WorkoutIntroSection -> WorkoutIntroScreen` branch gate are validated. Workout/Nutrition/Targets/Review owners, secure resume, persistence, and explicit completion/status gating remain pending. |
| Mode-dependent guided navigation | Validated | `apps/app`, `apps/core` | Visible tabs and route policy match all three guided layouts; unavailable routes reconcile to Home and Coach remains deferred. Controller, route-policy, and widget tests pass. |
| Profile, photo preview, and Settings entry | Implemented | `apps/features/profile`, `apps/features/settings`, `apps/app`, `apps/core` | Home exposes a 36dp Profile avatar. Profile uses an actionable 80dp avatar and opens a centered full-screen 1:1 photo route with a 160dp fallback; media actions remain disabled until real Profile Storage handlers exist. Settings remains Profile-owned. |
| Custom three-to-six destination layout | Documented | `apps/shared`, Settings, `apps/app`, `apps/core` | Final-stage target only. No destination registry, preference, eligibility resolver, or Settings editor exists. |
| Adaptive Home and action entry | Documented | Home composition, affected feature owners, `apps/core` | No surface-composition or action-entry system exists. Start/resume workout and meal-log workflows remain future feature work. |
| Reusable `TioAvatar` | Implemented | `apps/core` | Shell, Profile, and photo fallback use the shared component. Five semantic sizes, Free/Plus/Pro frame variants, circle/rounded/hexagon presentation, optional image, initials/icon/error fallback, and caller-supplied semantics have widget coverage. `extraLarge` suppresses plan frames; entitlement and Profile upload/storage remain future work. |
| Reusable `TioButton` | Implemented | `apps/core` | Primary, secondary, and ghost variants share token-driven size, spacing, pressed/focus/hover/disabled states, loading lockout, live semantics, and reduced-motion behavior. Onboarding and Settings mode actions consume the loading contract. |
| Material 3 Expressive | Implemented | `apps/core` | Theme/navigation/avatar/button contracts and Welcome semantic contrast are implemented. Automated checks plus Pixel 9 light/dark and compact-width validation pass; OLED, keyboard/focus, and screen-reader checks remain. |
| Workout Library | Documented | `apps/features/workout` | It is planned as a Workout route and may become a promoted custom shortcut only after implementation. |
| Routine/Program workout flow | Documented | `apps/features/workout` | Target is Routine/Program-first; no standalone Quick Start. Current route is a shell placeholder. |
| Exercise Search | Documented | `apps/features/workout` | Planned nested Routine/Program editor screen using a validated versioned local JSON catalog; no route or asset exists yet. |
| Active Workout | Documented | `apps/features/workout` | Planned selected Routine/Program execution flow with set input and rest timer; no execution or persistence is verified. |
| Workout heatmap, radar map, and calendar | Documented | `apps/features/workout` | Planned only after recorded workout history exists; no visualizations are verified in source. |
| Nutrition diary | Documented | `apps/features/nutrition` | No production diary flow is verified in the current source. |
| Meal Plan | Documented | `apps/features/nutrition` | Deferred until after the first nutrition MVP; future custom promotion does not change ownership. |
| Flutter Wear OS companion | Scaffolded | `apps/wear` | The Flutter package and watch-first home tiles exist. Tile selection currently displays `coming soon`. |
| Wear workout controls | Documented | `apps/wear`, Workout contracts | Future lightweight companion scope only. |
| Wear nutrition quick actions | Documented | `apps/wear`, Nutrition contracts | Future quick add, water, and summary scope only; no full diary or Meal Plan editing. |
| Apple Watch companion | Documented | future `apps/watchos` | Native Swift + SwiftUI direction; no implementation is verified here. |
| Recovery | Documented | future `apps/features/recovery` | First outcome, data source, privacy/sync boundary, and non-medical scope are undecided; no package or route exists. |
| Screen catalog and module plan | Documented | `docs/screens/` | Source-based per-screen plan exists; it does not change runtime behavior. |

## Update Rules

- Move a row forward only after inspecting the affected source and running the stated validation.
- If a capability is partially built, describe the working boundary instead of upgrading its status.
- Link implementation-specific plans from [tasks/README.md](tasks/README.md); keep long design rationale in canonical docs or ADRs.

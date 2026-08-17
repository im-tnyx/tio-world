# Active Decisions

This log records durable product and architecture choices. It is a concise orientation aid; canonical architecture and roadmap documents remain authoritative.

| ID | Status | Decision | Rationale and boundary |
|---|---|---|---|
| D-001 | Active | Wear OS stays Flutter in `apps/wear`. | It preserves the existing working Wear package and Flutter-first product direction. This supersedes earlier documentation that described native Wear OS. Apple Watch remains native Swift + SwiftUI. |
| D-002 | Active | `AppMode` belongs in `apps/shared` with `workout`, `nutrition`, and `hybrid` values. | The implemented pure-Dart shared contract lets every phone feature read one mode without cross-feature ownership violations. |
| D-003 | Active | The phone's guided default tabs are derived from `AppMode`, not fixed. | Workout: Home/Workout/Progress. Nutrition: Home/Nutrition/Progress. Hybrid: Home/Workout/Nutrition/Progress. Coach becomes eligible in Phase 7. |
| D-004 | Active | Home is the mobile primary-tab name. | Do not reintroduce the former Dashboard label in new product or UI documentation. |
| D-005 | Superseded by D-014 | Workout Library is a Workout route; Meal Plan is a later Nutrition route. | Ownership and delivery order remain valid. The absolute prohibition on tab promotion is superseded by the future promoted-shortcut policy. |
| D-006 | Active; implemented | `apps/core` owns one reusable `TioAvatar`. | Semantic sizes are `compact`, `small`, `medium`, `large`, and `extraLarge`. Free has no plan frame, Plus uses a semantic circular ring, Pro uses a semantic hexagon, and `extraLarge` ignores plan frames. Image/fallback/semantics behavior stays centralized. |
| D-007 | Active | Wear OS future scope includes workout controls and nutrition quick actions. | Keep heavy interaction on phone: no full food search, full nutrition diary, or Meal Plan editing. After phone Meal Plan exists, Wear may show only the next planned meal status. |
| D-008 | Active; first slice implemented | Phone UI adopts Material 3 Expressive through `apps/core`. | Theme accessibility behavior, guided `NavigationBar`, `TioAvatar`, and `TioButton` are implemented with automated coverage. Continue shared-component migration incrementally; manual device/accessibility checks remain. Do not depend on an assumed separate Flutter M3 Expressive API. Wear remains compact and watch-first. |
| D-009 | Target, not implemented | Recovery will be an independent future `apps/features/recovery` feature. | Do not create it until a narrow first user outcome, data source, privacy/sync boundary, and non-medical scope are approved. It is not a primary App Mode tab. |
| D-010 | Target, not implemented | Workout is Routine/Program-first and owns its training visualizations. | Do not add standalone Quick Start. Start active sessions from a selected Routine or Program session. Exercise Search is nested and reads a validated versioned local JSON catalog. Muscle heatmap, accessible training radar map, and calendar use recorded workout history; Recovery context is conditional. |
| D-011 | Target, not implemented | Profile-derived defaults do not change domain ownership. | Profile supplies approved context. Nutrition owns targets/overrides; Workout owns settings/defaults. Feature calculations use stable contracts and never silently replace user overrides. |
| D-012 | Target, not implemented | Supabase is the first Auth, data, and Storage platform. | Use Supabase Auth and RLS-protected Postgres for user data. Custom protected backend code and Gemini are future upgrades, not current clients or repo modules. |
| D-013 | Target, not implemented | Module media uses private Supabase Storage buckets. | `profile`, `nutrition`, `workout`, and `progress` hold only approved user media. Structured data remains in Postgres; each bucket needs owner-specific policies and a concrete file slice before provisioning. |
| D-014 | Target, not implemented | Future adaptive navigation keeps three App Modes, Home fixed first, and three to six eligible selections. | Guided defaults ship first. Later custom layouts may promote implemented owner routes such as Routine Library or Meal Plan, adapt Home/feature section prominence, and move action entry points without duplicating feature workflows. Active Workout remains resumable independent from tab order. |
| D-015 | Active | Persist the confirmed App Mode device-locally for the first slice. | `apps/shared` owns the pure-Dart preference contract and `apps/app` wires a `SharedPreferencesAsync` adapter. Missing/invalid data returns to mode selection. Supabase account sync is deferred until an approved profile contract exists. |
| D-016 | Active; routed parent flow implemented | Full onboarding uses one `/onboarding` parent; the unnumbered App Mode gate shows Back-only fixed-height chrome and hides progress, while later children keep fixed Back/progress and a fixed bottom primary action. | Stable mode-derived step IDs and one Riverpod controller own internal flow. App Mode is excluded from progress position/total; every later user-facing child advances progress. Draft mode, confirmed App Mode, and completion status stay separate. Sensitive draft persistence and cross-owner finalization remain implementation-gated. |

## Maintenance Rules

- Add a decision only when it changes product scope, module ownership, platform strategy, data flow, or a durable implementation constraint.
- When a decision changes, retain the old entry with status `Superseded` and add a new entry that names it.
- Link the decision to canonical docs or source when the detail is non-obvious.
- Do not use this file for temporary terminal results, branch state, or personal notes.

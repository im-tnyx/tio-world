# Project Context

Document Status: Canonical Live Doc
Last Verified: 2026-09-27
Owner: repository AI governance
Truth Boundary: Concise AI-facing product/repository orientation; canonical product/architecture docs, runtime source/config, and live trackers override current-state details.

**TNYX / tio-world** is an AI health, fitness, nutrition, recovery, coaching, workout, wearable, and future multi-platform product.

The current target repository direction is a **Flutter-first monorepo** with a Flutter Wear OS companion and a future native Apple Watch app.

## Current Platform Scope

The repository uses the following apps-based structure:

- `apps/app`: Flutter phone app for Android and iPhone.
- `apps/wear`: Flutter Wear OS companion app with watch-first UI and shared contracts where useful.
- `apps/watchos`: Native Apple Watch app using Swift + SwiftUI when introduced.
- `apps/shared`: Pure Dart models, entities, repository contracts, use cases, result/error types, and shared utilities.
- `apps/core`: Flutter design system, app shell UI, route contracts, reusable widgets, and theme tokens.
- `apps/features/*`: Feature-owned Flutter UI, state, controllers, and presentation workflows.
- `supabase/` (active): Supabase Auth, Postgres/RLS, Storage, migrations, and approved server functions.
- future `services/api`: Sole protected application-service path when a separately approved slice needs it; server-side AI/provider orchestration and advanced integrations belong here when Supabase functions are no longer the right boundary.
- future `services/worker`: Add only for a real separately approved asynchronous/background workload.

## Current Product Areas

Core product areas are:

- Auth
- Onboarding
- Home
- Workout
- Nutrition
- Coach
- Progress
- Profile
- Settings
- Wear OS
- Apple Watch
- Sync
- Supabase / protected backend / AI Coach

## App Mode System

The phone experience uses one implemented `AppMode` enum in `apps/shared`: `workout`, `nutrition`, or `hybrid`. Pre-auth account setup may stage the choice locally, while authenticated Settings writes the canonical value through the shared App Preferences contract to `public.user_app_preferences`; local SharedPreferences is staging/cache rather than authenticated truth. The visible `go_router` `StatefulShellRoute` tabs follow the resolved mode: workout has Home/Workout/Progress; nutrition has Home/Nutrition/Progress; hybrid has all four. Product Onboarding is implemented as one parent flow with remaining owner/final-acceptance gates tracked separately. Workout Library is a Workout route, while Meal Plan is a post-MVP Nutrition route. Coach is added to every mode in Phase 7.

## Watch Strategy

Watch apps are product-critical. Wear OS uses Flutter in `apps/wear` for workout controls and nutrition quick actions, while Apple Watch uses Swift/SwiftUI.

Use:

- Wear OS: Flutter.
- Wear OS product lanes: workout controls plus food, water, and today's nutrition summary quick actions.
- Wear OS future Meal Plan view: next planned meal status only after mobile Meal Plan exists; no full diary or plan editing.
- Apple Watch: Swift + SwiftUI.
- Mobile app: Flutter.
- Shared Flutter feature contracts: `apps/shared`; reusable lightweight primitives: `apps/core`; platform-specific integrations and stable sync contracts where useful.

## Current Status

`tio-world` is an active Flutter/Supabase monorepo with multiple implemented feature and platform slices, while several product areas and future protected services remain incomplete or planned.

Do not infer production readiness from docs, implemented slices, placeholder modules, or planned folders; runtime/source and release acceptance remain the proof.

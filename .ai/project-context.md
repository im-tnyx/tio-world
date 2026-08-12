# Project Context

**TNYX / tio-world** is an AI health, fitness, nutrition, recovery, coaching, workout, wearable, and future multi-platform product.

The current target repository direction is a **Flutter-first monorepo** with a Flutter Wear OS companion and a native Apple Watch app.

## Current Platform Scope

The repository uses the following apps-based structure:

- `apps/app`: Flutter phone app for Android and iPhone.
- `apps/wear`: Flutter Wear OS companion app with watch-first UI and shared contracts where useful.
- `apps/watchos`: Native Apple Watch app using Swift + SwiftUI when introduced.
- `apps/shared`: Pure Dart models, entities, repository contracts, use cases, result/error types, and shared utilities.
- `apps/core`: Flutter design system, app shell UI, route contracts, reusable widgets, and theme tokens.
- `apps/features/*`: Feature-owned Flutter UI, state, controllers, and presentation workflows.
- future `supabase/`: Supabase Auth, Postgres/RLS, private Storage buckets, migrations, and seed data.
- future `backend/api`: Protected service API boundary after the Supabase-first upgrade gate.
- future `backend/ai-coach`: Server-side Gemini/provider coaching layer.
- future `backend/jobs`: Long-running scheduled and background jobs after the upgrade gate.

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

The phone experience uses one implemented `AppMode` enum in `apps/shared`: `workout`, `nutrition`, or `hybrid`. Onboarding's first screen selects it, Settings changes the same device-local preference, and the visible `go_router` `StatefulShellRoute` tabs follow it: workout has Home/Workout/Progress; nutrition has Home/Nutrition/Progress; hybrid has all four. Later mode-conditional onboarding steps remain planned. Workout Library is a Workout route, while Meal Plan is a post-MVP Nutrition route. Coach is added to every mode in Phase 7.

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

`tio-world` should be treated as a foundation-stage monorepo until real modules, apps, and backend services are implemented.

Do not infer production readiness from docs, placeholder modules, or planned folders.

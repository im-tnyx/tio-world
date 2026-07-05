# Project Context

**TNYX / tio-world** is an AI health, fitness, nutrition, recovery, coaching, workout, wearable, and future multi-platform product.

The current target repository direction is a **Flutter-first monorepo** with native watch apps.

## Current Platform Scope

Expected root structure:

- `apps/mobile`: Flutter mobile app for Android phone and iPhone.
- `apps/wear-os`: Native Wear OS companion app using Kotlin + Compose for Wear OS.
- `apps/watchos`: Native Apple Watch app using Swift + SwiftUI.
- `packages/core_models`: Shared Dart domain models.
- `packages/api_client`: API client and DTO mapping for Flutter/mobile layers.
- `packages/workout_engine`: Workout calculations and reusable workout logic.
- `packages/nutrition_engine`: Nutrition calculations and reusable nutrition logic.
- `packages/sync_core`: Shared sync rules for mobile app flows.
- `packages/design_system`: Flutter design tokens and reusable mobile UI primitives.
- `backend/api`: Backend API boundary.
- `backend/ai-coach`: Server-side AI coaching layer.
- `backend/db`: Database schema, migrations, and seed data.

## Current Product Areas

Core product areas are:

- Auth
- Onboarding
- Dashboard / Home
- Workout
- Nutrition
- Coach
- Progress
- Profile
- Settings
- Wear OS
- Apple Watch
- Sync
- Backend / AI Coach

## Watch Strategy

Watch apps are product-critical, but they should not be forced through Flutter UI.

Use:

- Wear OS: Kotlin + Compose for Wear OS.
- Apple Watch: Swift + SwiftUI.
- Mobile app: Flutter.
- Shared business rules: Dart packages for mobile, backend contracts where useful, and platform-native watch logic where needed.

## Current Status

`tio-world` should be treated as a foundation-stage monorepo until real modules, apps, and backend services are implemented.

Do not infer production readiness from docs, placeholder modules, or planned folders.

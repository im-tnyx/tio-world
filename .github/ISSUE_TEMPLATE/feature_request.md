---
name: Feature request
about: Propose a new product capability for tio-world
title: "feature: "
labels: enhancement
assignees: ""
---

## Summary

Describe the requested feature in 1-3 sentences.

## User Problem

What user need does this solve?

Who benefits from it?

- [ ] New user
- [ ] Active workout user
- [ ] Nutrition tracking user
- [ ] Coach / AI guidance user
- [ ] Wear OS user
- [ ] Apple Watch user
- [ ] Admin / internal operator
- [ ] Developer / contributor

## Proposed Behavior

Describe the expected workflow.

Include important states such as loading, empty, error, offline, sync pending, and permission denied where relevant.

## Product Area

- [ ] Auth
- [ ] Onboarding
- [ ] Home
- [ ] Workout
- [ ] Nutrition
- [ ] Coach
- [ ] Progress
- [ ] Profile
- [ ] Settings
- [ ] Sync
- [ ] Notifications
- [ ] Wear OS
- [ ] watchOS
- [ ] Backend / API
- [ ] AI coach
- [ ] Tooling / docs
- [ ] Other

## Platform Scope

- [ ] Flutter mobile app: Android
- [ ] Flutter mobile app: iOS
- [ ] Flutter Wear OS app
- [ ] Native watchOS app
- [ ] Backend / API
- [ ] AI coach
- [ ] Database / migrations
- [ ] Documentation only

## Ownership

Which area should own the UI, navigation, business logic, storage, sync, and API contract?

If unsure, explain the options considered.

Suggested ownership model:

- Flutter phone UI belongs in `apps/app` or an owning `apps/features/*` package.
- Reusable Dart logic belongs in `apps/shared`; reusable Flutter UI belongs in `apps/core`.
- Wear OS UI belongs in `apps/wear`.
- Apple Watch UI belongs in `apps/watchos`.
- Backend behavior belongs in `backend/*`.
- Shared API contracts belong in the documented contract/package layer.

## Architecture Impact

Does this affect feature boundaries, routing, state management, repositories, API contracts, sync, database schema, watch communication, privacy, or security?

- [ ] No architecture impact expected
- [ ] UI/routing impact
- [ ] State management impact
- [ ] Repository/data impact
- [ ] Backend/API impact
- [ ] Database/migration impact
- [ ] Watch sync impact
- [ ] Privacy/security impact

## Acceptance Criteria

- [ ]
- [ ]
- [ ]

## Notes / References

Add sketches, links, screenshots, related issues, or product notes if available.

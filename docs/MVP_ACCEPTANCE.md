# MVP Acceptance Gates

## Purpose

This checklist defines the minimum evidence needed to close the first Tio vertical slices. It is a delivery reference, not a claim that any listed capability is implemented or approved for release.

Each feature task must link the affected [screen specifications](screens/README.md), record actual validation, and retain its own scope and non-goals.

## Global Gate For Every Slice

Before a slice is called complete:

- [ ] Ownership is clear: shell, feature package, shared contract, repository, and platform responsibility are documented.
- [ ] The UI has loading, empty, error, retry, and offline behavior appropriate to the data boundary.
- [ ] Sensitive health, nutrition, workout, recovery, profile, and media data are not logged or exposed through client secrets.
- [ ] The screen uses `apps/core` tokens/components and meets the [UI/UX System](UX_UI_SYSTEM.md) accessibility baseline.
- [ ] Feature business logic is not placed in `apps/app`, `apps/core`, or Flutter widgets.
- [ ] Applicable static analysis and focused tests have run, or an exact limitation is recorded.
- [ ] Runtime behavior, task brief, implementation status, and canonical docs agree before a completion claim.

## 1. App Mode Foundation

**Approved start boundary:** Persist the confirmed mode device-locally for the first slice. Defer account sync until an approved Supabase profile contract exists.

- [ ] `AppMode` is a single pure-Dart contract in `apps/shared` with `workout`, `nutrition`, and `hybrid`.
- [ ] Onboarding begins with mode selection and later steps are conditioned by mode.
- [ ] Settings reads and changes the same mode through the approved preference boundary.
- [ ] The confirmed mode survives an app restart; missing or invalid local data returns to mode selection safely.
- [ ] `StatefulShellRoute` derives the guided layout from mode and safely handles a mode change while a destination is selected.
- [ ] Workout Library and Meal Plan are not added to the guided default tabs; later custom promotion remains outside the MVP. Coach remains deferred to Phase 7.
- [ ] Contract, state mapping, and navigation selection have focused automated coverage.

## 2. First Supabase-Backed Slice

**Start gate:** Confirm the first authenticated feature and supported sign-in methods. Do not provision generic tables, buckets, or providers ahead of that slice.

- [ ] The feature repository contract exists before its client data source.
- [ ] Only the minimum `supabase/` configuration, migration, RLS policies, and client-safe configuration required by the approved slice are introduced.
- [ ] Every client-accessible table, view, function, and Storage object has explicit authorization design; exposed data tables use ownership-safe RLS.
- [ ] No service-role key, Gemini key, admin action, or privileged operation reaches phone or Wear OS clients.
- [ ] Local/offline state, session expiry, authorization denial, cancellation, retry, and conflict behavior are specified for the slice.
- [ ] Security/RLS review and the relevant migration or repository tests have been run and recorded.

## 3. Workout MVP

- [ ] The user can browse/select a Routine or Program and begin an active session only from that selected context.
- [ ] Active Workout supports the approved logging behavior, set input, rest timing, and interruption/recovery states for its scope.
- [ ] Exercise Search is nested within the Routine/Program flow and uses a validated, versioned local JSON catalog before any remote catalog is approved.
- [ ] Workout data remains behind Workout-owned contracts and repositories; screens do not expose database DTOs.
- [ ] Muscle heatmap, radar map, and calendar remain unavailable until recorded workout history exists; their empty/data-insufficient state is defined.

## 4. Nutrition Diary MVP

- [ ] Nutrition owns meal, food, calorie, macro, water, target, validation, and override behavior.
- [ ] Nutrition targets may use approved Profile context as defaults but never overwrite confirmed user choices silently.
- [ ] Food/meal logging has empty, loading, error, retry, and offline/pending behavior suitable for the approved persistence model.
- [ ] Meal Plan remains deferred until the diary MVP is validated.
- [ ] Optional meal images require the approved private Storage boundary before upload is enabled.

## 5. Progress MVP

- [ ] Progress owns weight, measurements, photos, streaks, trends, achievements, and analytics presentation for the approved scope.
- [ ] No trend, streak, or chart is presented as meaningful when data is missing or insufficient.
- [ ] Progress photos are not enabled until the private `progress` Storage policy and consent/retention requirements are approved.
- [ ] Sensitive data is shown and logged according to the Security and privacy boundary.

## 6. Wear OS MVP

- [ ] Wear implementation remains in `apps/wear` and is validated on an emulator plus a physical watch when available.
- [ ] Workout actions are short, glanceable, and use approved shared contracts rather than copied phone presentation logic.
- [ ] Nutrition scope is limited to approved quick actions, water add, and summary. Full diary and Meal Plan editing stay on phone.
- [ ] Offline, reconnect, permission-unavailable, and sync-placeholder behavior are defined honestly for the delivered scope.
- [ ] No sensor access, real sync, authentication, notification, tile, complication, or workout-runtime capability is claimed without source and validation evidence.

## 7. Before Photo Collection Or AI

These are mandatory product/legal/security gates, not assumptions an implementation task may fill in silently:

- [ ] Explicit consent and user-visible explanation for sensitive data collection.
- [ ] Retention, deletion, export, and account-deletion behavior approved for the data type and supported jurisdictions.
- [ ] Image MIME, size, processing, metadata, overwrite, deletion, and offline-upload policies defined before any bucket is provisioned.
- [ ] Gemini/AI use case, allowed input data, safety boundary, cost/rate-limit policy, logging redaction, and server-side authorization model approved before provider integration.

## Related

- [Roadmap](ROADMAP.md)
- [Supabase-First Platform Strategy](SUPABASE_STRATEGY.md)
- [Security](SECURITY.md)
- [Testing Guide](TESTING_GUIDE.md)
- [Feature Development Workflow](../.ai/FEATURE_DEVELOPMENT.md)

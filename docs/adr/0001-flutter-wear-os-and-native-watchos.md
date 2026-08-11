# ADR-0001: Flutter Wear OS and Native Apple Watch

- **Status:** Accepted
- **Date:** 2026-08-11

## Context

Tio needs a lightweight smartwatch companion for workout controls and nutrition quick actions. The repository already contains a working Flutter package at `apps/wear`. Apple Watch is a separate platform with native SwiftUI, HealthKit, and WatchConnectivity requirements.

Earlier documentation described Wear OS as native, which conflicted with the existing Flutter package and the Flutter-first product direction.

## Decision

- Keep Wear OS in Flutter under `apps/wear`.
- Keep a future Apple Watch app native under `apps/watchos`, using Swift and SwiftUI.
- Reuse pure-Dart contracts and lightweight design primitives where appropriate, while keeping each watch UI platform-specific and watch-first.

## Consequences

### Positive

- The existing Wear OS package remains usable and does not need a disruptive rewrite.
- Phone and Wear OS can share stable Dart contracts without copying phone screens.
- Apple Watch can use native Apple platform integrations when that product slice is approved.

### Constraints

- `apps/wear` must remain compact, battery-aware, and independent from phone-scale layouts.
- Full nutrition diary editing, Meal Plan editing, long analytics flows, large imagery, and full AI chat stay on phone.
- This decision does not claim that workout controls, nutrition actions, sensor integration, authentication, or sync are implemented on Wear OS today.

## Related

- [Watch Strategy](../WATCH_STRATEGY.md)
- [Architecture](../ARCHITECTURE.md)
- [Wear Home screen specification](../screens/wear-home.md)
- [Active Decision D-001](../../.ai/DECISIONS.md)

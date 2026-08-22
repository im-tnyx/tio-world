# Product Onboarding O4A — Canonical Wellness Repository Contract

**Status:** In progress  
**Tracker:** #59  
**Parent O4:** #58  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Starting checkpoint:** O3 final `75237e6c…` / CI #1354 ✅  
**Implementation PR:** #50 Draft/open/unmerged

## Outcome

Create a backend-neutral canonical Wellness target contract and repository adapter for `public.user_wellness_targets` before moving onboarding runtime children.

## Domain contract

Represent only canonical Wellness target concepts:

```text
dailySteps?
waterMl?
sleepTargetMinutes?
bedTimeMinutes?
wakeTimeMinutes?
```

Null is unknown/unset. Canonical reads must not substitute onboarding UI defaults.

## Repository contract

```text
WellnessTargetsRepository
  read() -> WellnessTargetsData?
  upsert(WellnessTargetsData)
```

Production Supabase adapter:
- requires authenticated user for write;
- returns null for unauthenticated read;
- targets only `user_wellness_targets`;
- sends the complete canonical field set, including nulls when clearing unknown fields;
- strictly parses non-null numeric/time values;
- converts domain minutes-since-midnight ↔ SQL TIME inside the adapter.

## Owning package

Use `tio_feature_progress` as the existing canonical health/progress owner package, alongside Body ownership. Do not create a new feature package only for this persistence slice.

## Scope

- add `WellnessTargetsData` + `WellnessTargetsRepository`;
- add deterministic in-memory repository;
- add Supabase repository;
- export through `tio_feature_progress/progress.dart`;
- add focused domain/in-memory/Supabase contract tests;
- no Product Onboarding runtime placement edits;
- no Nutrition mirror cutoff in this slice.

## Acceptance

- [ ] backend-neutral nullable model;
- [ ] exact canonical table/payload contract;
- [ ] write authentication fails closed;
- [ ] read unauthenticated returns null;
- [ ] malformed values fail rather than fabricate;
- [ ] time conversion round-trips deterministically;
- [ ] complete null values can clear canonical columns;
- [ ] in-memory read/write deterministic;
- [ ] public export available;
- [ ] existing onboarding flow unchanged;
- [ ] full four-gate CI green on one exact source SHA.

## Guardrails

- no UI changes;
- no onboarding navigation changes;
- no migration edits;
- no legacy-column drops;
- no permanent dual-write;
- no anonymous-auth fallback;
- O4B blocked until O4A exact full CI green.

## Validation

Run full workspace CI after focused tests land:

```text
Flutter analyze
Dart analyze
Flutter tests
Dart tests
```

## Current work

**Implement only the canonical Wellness repository contract and focused tests.**

# Product Onboarding O4A — Canonical Wellness Repository Contract

**Status:** Validated  
**Tracker:** #59 ✅ closed  
**Parent O4:** #58  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Successor:** #60 O4B ACTIVE  
**Implementation PR:** #50 Draft/open/unmerged

## Final checkpoint

```text
f244b4913143ba8f76439a8b2554fd095d7e1973
Flutter CI #1365 / run 32563623833
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Validated outcome

`tio_feature_progress` now owns a backend-neutral canonical Wellness boundary:

```text
WellnessTargetsData
WellnessTargetsRepository
InMemoryWellnessTargetsRepository
SupabaseWellnessTargetsRepository
```

Canonical values remain nullable/unknown-safe:

```text
dailySteps?
waterMl?
sleepTargetMinutes?
bedTimeMinutes?
wakeTimeMinutes?
```

The Supabase adapter targets only `public.user_wellness_targets`, fails closed on unauthenticated writes, performs no anonymous-auth side effect, strictly parses malformed non-null state, preserves nulls without onboarding defaults, and converts minute-of-day values to/from SQL TIME deterministically.

## Scope preserved

O4A did not change onboarding runtime placement, Nutrition persistence, migrations, or UI. Existing Step/Sleep/Water screens remain under the legacy Targets runtime until O4B.

## Acceptance

- [x] backend-neutral nullable model;
- [x] exact canonical table/payload contract;
- [x] write authentication fails closed;
- [x] signed-out read returns null without DB access;
- [x] malformed values fail rather than fabricate;
- [x] time conversion round-trips deterministically;
- [x] null values can intentionally clear canonical columns;
- [x] in-memory read/write deterministic;
- [x] public export available;
- [x] existing onboarding runtime unchanged;
- [x] full four-gate CI green on exact source SHA.

## Exit

**O4A is complete. O4B runtime Wellness section/navigation/resume is active on #60.**

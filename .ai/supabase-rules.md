# Supabase Architecture & Rules

## Active Production Foundation (Supabase-First)

Tio-World uses Supabase as its active data, authentication, and storage platform.

- **Auth:** Supabase Auth (`GoTrue`) with direct token management and stream observation.
- **Database:** Supabase PostgreSQL with strict Row Level Security (RLS) on all user-owned tables (`users`, `user_workout_preferences`, `user_targets`).
- **Storage:** Private/public module buckets (`avatars`) with path ownership policies (`auth.uid() = foldername`).

## Future-Safe Backend Preservation Rule

Tio-World currently uses **Supabase as the active production data boundary**, but the repository has already-established **future custom-backend infrastructure**.

The following code is intentional architecture and MUST NOT be deleted, merged away, replaced, or classified as dead/unused code merely because it is not active in the current Supabase production composition:

* `ApiClient`
* `DioApiClient`
* `AuthTokenProvider`
* `RemoteProfileSetupRepository`
* `ProfileSetupDtoMapper`
* `RemoteWorkoutPreferencesRepository`
* `WorkoutPreferencesDtoMapper`
* `RemoteTargetsSetupRepository`
* `TargetsSetupDtoMapper`
* `RemoteOnboardingFinalizer`
* `BackendUserSyncRepository`
* `RemoteBackendUserSyncRepository`
* `GoogleAuthUseCase` (Firebase + custom backend path)
* backend transport DTOs and mappers

### Current vs Future Adapter Rule

Current production path:
```text
Flutter → existing repository contracts → Supabase adapters → Supabase Auth + Postgres/RLS
```

Future backend path:
```text
Flutter → SAME repository contracts → Remote*/HTTP adapters → custom Tio backend
```

A model, coding agent, cleanup task, dead-code audit, refactor, or architecture migration MUST NOT delete inactive Remote*/HTTP/backend infrastructure solely because Supabase is the current production adapter.

Inactive != obsolete.

Removal requires:
1. architecture audit,
2. explicit retirement decision,
3. explicit user approval.

# Supabase Foundation

**Status:** Needs decision
**Primary owners:** future `supabase/`, `apps/shared`, affected feature package, `apps/app`
**Affected platforms:** Flutter phone, Flutter Wear OS, future protected server boundary

## 1. Discovery

### User Outcome

Use Supabase as the first authenticated data foundation for Tio. Keep a separate protected backend as a future upgrade and keep Gemini API calls server-side only when an approved AI slice needs them.

### Success Criteria

- The first approved feature has Supabase Auth, data ownership, RLS, and client/repository boundaries defined.
- Any approved module media uses a private owner-safe Storage bucket rather than an unstructured shared bucket.
- No service-role or Gemini credential reaches a mobile/watch client or repository.
- The repository introduces only the configuration, migration, and code required for the first vertical slice.

### Non-Goals

- Full product schema, generic backend, Gemini integration, or live Supabase provisioning now.
- Selecting an unconfirmed custom backend framework.

## 2. Codebase Exploration

- No `supabase/` or `backend/` directory exists in the current checkout.
- Login is UI-only; no auth provider, session, package, or client configuration is implemented.
- App Mode, Profile, Workout, Nutrition, and Progress data contracts are documented but not implemented.

## 3. Clarification

| Decision | Status | Rationale |
| :--- | :--- | :--- |
| First authenticated vertical slice | Needed | Defines the minimum Auth, table, RLS, and repository scope. |
| Sign-in methods | Needed | Current Login buttons are placeholders; do not enable providers without UX/privacy decisions. |
| App Mode persistence | Decided | Device-local first; account sync is deferred until an approved Supabase profile contract exists. |
| Gemini runtime and use case | Deferred | Decide only with the Phase 7 Coach/AI slice. |
| Separate backend framework | Deferred | `fat secrate` is not an identified framework; do not create a dependency until its exact name and need are confirmed. |
| Module Storage buckets | Target | `profile`, `nutrition`, `workout`, and `progress` are private user-media buckets. Provision only with the first concrete file use case. |

## 4. Architecture Design

### Chosen Approach

Supabase owns Auth and RLS-protected user data. Feature repositories hide the client/data source. Gemini calls, service-role work, and privileged operations stay behind a protected server-side boundary.

### Ownership And Data Flow

```text
Flutter feature UI -> controller -> repository contract -> client-safe Supabase data source
Protected AI request -> authenticated/authorized server boundary -> Gemini -> shaped safe response
```

### Alternative Rejected

Building a custom auth/database backend before a first data slice is rejected because it delays the MVP without validating its needed service boundary.

### Failure And Accessibility States

Auth cancellation, invalid session, expired session, authorization denial, offline/local pending state, and retry behavior must be designed for the first slice.

## 5. Implementation Plan

- [ ] Confirm the first feature and supported sign-in methods.
- [ ] Add the minimum Supabase configuration and untracked environment template only after approval.
- [ ] Add the smallest required data policy/migration through the documented Supabase workflow.
- [ ] Implement feature repository and focused Auth/data tests.
- [ ] Add Gemini only in a separately approved Coach/AI task.

## 6. Quality Review

- Review RLS, ownership, user-metadata, secret, logging, offline, and session-expiry boundaries.
- Run the relevant Supabase security/advisor checks only once a project and migration exist.

## 7. Final Handoff

### Actual Behavior

Documentation-only plan. No Supabase, Gemini, backend, or client behavior has changed.

### Final Status

`BLOCKED`

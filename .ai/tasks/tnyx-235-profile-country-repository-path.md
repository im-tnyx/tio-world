# TNYX-235 — Wire canonical Profile country through app repository path

**Status:** In progress  
**Primary owner:** TNYX-235 / Profile  
**Affected platforms:** Flutter Profile domain/data

## Owner Approval and Scope Boundary

**Trigger:** None  
**Approval status:** Not required  
**Approval evidence:** This is a bounded implementation subtask required to complete the already approved natural-language meal logging path. No new product-visible UI and no Supabase shape change.
**Approved product/UI/data-shape boundaries:** Reuse existing nullable `public.user_profiles.country_code`; extend canonical Profile model/repository only.
**Explicit non-changes:** No new UI, no migration/RLS/RPC, no Edge Function deploy, no provider/backend changes, no TNYX-226 activation.

## Active Handoff

**Planning owner:** ChatGPT / Linear  
**Implementation owner:** ChatGPT  
**Review owner:** ChatGPT  
**Implementation ownership state:** Active  
**Ownership transition:** Not applicable  
**Repository state last verified:** `main@316d9a8229a29935d6b9e6669cfcc4eb06c06e31`  
**Branch:** `tnyx/tnyx-235-n5d-7e-wire-canonical-profile-country-through-app-repository`  
**HEAD SHA:** `316d9a8229a29935d6b9e6669cfcc4eb06c06e31`  
**Observed working-tree state:** API-based agent; branch created from exact main  
**Observed uncommitted/dirty files:** Not applicable through GitHub API  
**PR / tracker:** Linear TNYX-235 In Progress; no PR yet  
**Current implementation state:** Ready for bounded Profile contract/repository change  
**Relevant execution surface:** `apps/features/profile/lib/src/domain/models/user_profile_data.dart`, `apps/features/profile/lib/src/data/repositories/supabase_user_profile_repository.dart`, focused tests  
**Validation completed at SHA:** Not run yet  
**Validation remaining:** focused Flutter tests / repository validation  
**Current blocker:** None for internal contract wiring  
**Open review finding IDs:** None  
**Next exact action:** Add nullable canonical country to Profile model/repository and focused tests without adding UI.

## 1. Discovery

### User Outcome

Allow the authenticated app Profile path to carry the canonical saved country required by the protected meal parser.

### Success Criteria

- Nullable country is represented by canonical Profile.
- Uppercase two-letter values round-trip.
- Invalid/lowercase values fail closed.
- Existing callers remain valid when country is unset.
- No visible UI changes.

### Scope

Profile domain/data contract and focused tests only.

### Non-Goals

No country picker, no inference/default, no schema change, no deploy, no TNYX-226 UI.

## 2. Codebase Exploration

### Verified Evidence

- DB already owns nullable `user_profiles.country_code` with uppercase two-letter check.
- Parser reads signed-in user's `country_code`.
- `UserProfileData` currently has no country field.
- `SupabaseUserProfileRepository` currently neither selects nor writes `country_code`.
- Existing repository already uses authenticated `currentUser.id` and RLS-scoped `user_profiles`.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Country owner | Locked | Canonical Profile / `user_profiles.country_code` | TNYX-233 |
| Null semantics | Locked | Unknown/unset, never inferred | TNYX-233 |
| Normalization | Locked | Reject invalid/lowercase rather than guessing | TNYX-235 |

## 4. Architecture Design

### Chosen Approach

Add optional `countryCode` to `UserProfileData`; validate only uppercase ISO-like two-letter shape. Include `country_code` in Supabase select/upsert.

### Ownership and Data Flow

```text
Profile caller -> UserProfileData.countryCode -> UserProfileRepository -> public.user_profiles.country_code
protected parser -> authenticated RLS read -> same country_code
```

### Alternative Rejected

Separate Nutrition-owned country field. That would duplicate source of truth and violate TNYX-233.

### Failure and Accessibility States

Invalid canonical country throws before persistence. Null remains valid.

## 5. Implementation Plan

- [ ] Extend `UserProfileData`.
- [ ] Extend Supabase repository select/parse/upsert.
- [ ] Update focused repository tests.
- [ ] Run validation.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Pending.

### Known Limitations

No product-visible country selection UI is introduced in this slice.

### Final Status

`PARTIAL`

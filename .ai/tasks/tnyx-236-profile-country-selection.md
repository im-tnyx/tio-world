# TNYX-236 — Minimal Profile country selection

**Status:** In progress  
**Primary owner:** TNYX-236 / Profile  
**Affected platforms:** Flutter Profile/Settings composition

## Owner Approval and Scope Boundary

**Trigger:** Product-visible UI change  
**Approval status:** Approved  
**Approval evidence:** Owner said “go” after the exact proposed behavior: Profile/Settings Country row → country selector → explicit user selection → canonical country save.  
**Approved boundary:** Minimal country field/editor using existing Profile Settings geometry and existing canonical `user_profiles.country_code`.  
**Explicit non-changes:** No broad redesign, no schema/RLS/RPC, no parser deploy, no TNYX-226 activation, no inferred/default country.

## Active Handoff

**Planning owner:** ChatGPT / Linear  
**Implementation owner:** ChatGPT  
**Review owner:** ChatGPT  
**Repository state last verified:** `main@1c959b3a5e72629e61481d4fe6c8d8e026a06a9e`  
**Branch:** `tnyx/tnyx-236-n5d-7f-profile-country-selection`  
**Current implementation state:** Discovery/audit complete; implementation next.

## Discovery / verified evidence

- TNYX-235 merged canonical nullable `UserProfileData.countryCode` and Supabase read/write support.
- Existing visible editor is `apps/features/settings/.../profile_settings_page.dart`, composed by `apps/app/.../profile_settings_route.dart`.
- Existing Profile Settings already uses capsule action fields and bottom-sheet selection for Biological Sex; country should preserve this geometry rather than invent a new surface.
- Existing app-level `CanonicalProfileSettingsRepository` reconstructs `UserProfileData` without `countryCode`, which would erase a saved country on unrelated Profile save.
- `SupabaseMeasurementUnitPreferencesRepository` has the same lost-country risk when updating units.
- Current repository parser uses generic optional-string trimming for country; country canonicality should fail closed rather than silently trim.
- No existing country selector is wired.
- Live Supabase remains 0 profiles with country and parser remains undeployed.

## Frozen architecture

```text
Profile Settings Country field
→ explicit selector
→ ISO alpha-2 code in UI state
→ ProfileSettingsUpdate
→ CanonicalProfileSettingsRepository
→ UserProfileData.countryCode
→ authenticated UserProfileRepository
→ public.user_profiles.country_code
```

Country remains Profile-owned. Settings only hosts the existing Profile editor/navigation.

## Implementation plan

- [ ] Add country to Profile Settings update contract/composition without changing unrelated ownership.
- [ ] Preserve current country in every partial canonical Profile rewrite.
- [ ] Add minimal Country action field using existing visual geometry.
- [ ] Use a bounded canonical ISO country option source; no locale/device inference.
- [ ] Add country-specific fail-closed parsing without whitespace normalization.
- [ ] Add focused domain/data/app/settings tests.
- [ ] Validate focused packages/CI.
- [ ] Draft PR only; no merge without explicit owner instruction.

## Non-goals

No Supabase mutation, deployment, provider calls, backend, Add Food activation, location permission, inferred country, or broad Settings/Profile redesign.

## Handoff

After merge, owner test account must explicitly select India through the normal authenticated app path. Live RLS readback must show `IN` before TNYX-229 deployment proceeds.

# Nutrition Profile Other details

Planned follow-up to Issue #147 after real-device confirmation.

- Add Health-style inline detail input when Diet Type = Other.
- Add Health-style inline detail input when Allergies & Restrictions includes Other.
- Keep detail text Nutrition-owned in onboarding draft persistence.
- Clear the corresponding detail when Other is no longer selected; selecting None clears restriction detail.
- Preserve detail through Back/resume/hydration.
- Keep Other detail optional, matching the existing Health Conditions interaction contract.
- No Supabase schema/data/config mutation.

Implementation must live on a separate stacked Draft PR and remain unmerged until explicit owner authorization.

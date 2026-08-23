# Product Onboarding O8D — Historical Snapshots + Autosave Recovery

**Status:** Active  
**Tracker:** GitHub Issue #86  
**Parent O8:** #82  
**O8A:** #83 ✅ / CI #1607  
**O8B:** #84 ✅ / CI #1610  
**O8C:** #85 ✅ / CI #1614  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged

## Starting exact validated checkpoint

```text
1591b37649a8e1d7913bf7322b200522db5773d1
Flutter CI #1614 / run 32628899085 / job 97168479612 ✅
Android Native CI #26 / run 32628899057 / job 97168479439 ✅
```

## Audit result

Existing O4 compatibility intentionally lets later top-level checkpoints remain later even when historical Wellness fields are absent. `TargetsOnboardingDraft` therefore carries compatibility UI defaults plus `has*Value` provenance, while `WellnessTargetsMapper` maps historically absent values to canonical `null`.

O8D must preserve that no-rewind contract without allowing Review to present compatibility defaults as explicit user truth.

Persistence already uses `ResumePreservingOnboardingDraftRepository`, which serializes saves and preserves the furthest still-valid durable cursor. Controller save failures retain active in-memory state and remain retryable on a later edit.

## Scope

- legacy missing Wellness values remain unknown through mapper/controller autosave/reload;
- Review renders unknown historical Steps/Hydration/Sleep as `Not set`, not numeric defaults;
- later Review checkpoint stays Review when otherwise valid;
- canonical Wellness mapping remains `null` for unknown historical fields;
- controller load failure preserves safe seed state and still completes hydration;
- failed debounced save retains in-memory answer;
- a later edit after repository recovery retries and persists the newest answer.

## Acceptance

- [ ] historical unknown Steps/Hydration/Sleep are not fabricated in Review;
- [ ] no forced rewind of otherwise-valid historical Review checkpoint;
- [ ] all unknown Wellness provenance flags survive autosave/reload;
- [ ] canonical Wellness mapper emits null for those unknown fields;
- [ ] hydration failure leaves seed/in-memory state intact and `isHydrated=true`;
- [ ] failed autosave does not erase active answer;
- [ ] later recovered autosave persists newest answer;
- [ ] no schema-version bump or migration edit;
- [ ] all Flutter/Dart gates green on one exact SHA;
- [ ] Android native debug build green on same SHA.

## Guardrails

- do not promote compatibility defaults to canonical truth;
- do not rewind later historical checkpoints solely because provenance is unknown;
- no broad resume/navigation rewrite;
- no O8E/O9 work until O8D freezes;
- PR #50 remains Draft/open/unmerged.

## Exit

Freeze O8D exact CI evidence, then activate O8E integrated O8 acceptance.

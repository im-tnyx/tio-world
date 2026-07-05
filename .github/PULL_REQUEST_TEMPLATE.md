## Summary

-

## Type Of Change

- [ ] Documentation
- [ ] Flutter mobile app
- [ ] Wear OS native app
- [ ] watchOS native app
- [ ] Backend / AI
- [ ] Shared Dart package
- [ ] Architecture
- [ ] Navigation / routing
- [ ] Data / sync / persistence
- [ ] UI / design system
- [ ] Build / tooling / CI

## Architecture And Documentation

- [ ] Relevant documentation updated.
- [ ] ADR updated or added if a durable architecture decision changed.
- [ ] Architecture changelog updated if module boundaries, routing, data flow, or engineering practice changed.
- [ ] Mobile/watch/backend progress doc updated if implementation status changed.
- [ ] No documentation change needed.

## Safety / Truth Boundary

- [ ] No secrets, service-role keys, keystores, private keys, signing files, or local `.env` values are included.
- [ ] No generated/cache/build artifacts are included.
- [ ] No APK, AAB, IPA, archive, or local release artifact is included.
- [ ] No live database migration, RLS, RPC, or schema change is implied unless it is actually included.
- [ ] Demo data is temporary scaffolding or clearly replaced by repository/API-backed data.
- [ ] Feature ownership follows the canonical docs.

## Definition Of Done

- [ ] Requirements implemented.
- [ ] Module ownership respected.
- [ ] Flutter screens/widgets remain presentation-only where applicable.
- [ ] Controller/notifier/use case/repository boundaries respected.
- [ ] Routing remains typed or centralized through the approved router.
- [ ] Native watch apps stay lightweight and do not duplicate heavy phone/backend behavior.
- [ ] Loading, empty, and error states considered where applicable.
- [ ] Unit/widget/integration tests pass or are consciously scoped out.
- [ ] Analyze/build checks pass or the reason is documented.
- [ ] No new warnings introduced.
- [ ] UI matches approved design/product direction, if applicable.
- [ ] Accessibility reviewed, if applicable.

## Validation

List commands actually run:

-

Examples:

```bash
melos analyze
melos test
cd apps/mobile && flutter test
cd apps/mobile && flutter analyze
pnpm test
```

## Notes

Add implementation notes, intentional deviations, or non-applicable checklist explanations.

// Narrow, backend-neutral Progress/Body/Wellness domain contracts for
// consumers such as Settings. No data adapters or presentation exports.
//
// Concrete repository selection and app-level provider composition remain
// owned by apps/app. The existing progress.dart entry point is unchanged.
export 'src/domain/body_setup.dart';
export 'src/domain/wellness_targets.dart';

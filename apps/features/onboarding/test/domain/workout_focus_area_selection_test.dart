import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  test('selecting full_body selects all individual areas too', () {
    final selected = WorkoutFocusAreaSelection.toggle(
      selectedAreas: const {},
      area: WorkoutFocusArea.fullBody,
    );

    expect(selected, contains(WorkoutFocusArea.fullBody));
    expect(
      WorkoutFocusArea.individualAreas.every(selected.contains),
      isTrue,
    );
  });

  test('deselecting an individual area removes full_body', () {
    final selected = WorkoutFocusAreaSelection.toggle(
      selectedAreas: {
        WorkoutFocusArea.fullBody,
        ...WorkoutFocusArea.individualAreas,
      },
      area: WorkoutFocusArea.arms,
    );

    expect(selected, isNot(contains(WorkoutFocusArea.fullBody)));
    expect(selected, isNot(contains(WorkoutFocusArea.arms)));
  });

  test('manually selecting every individual area auto-adds full_body', () {
    var selected = <WorkoutFocusArea>{};

    for (final area in WorkoutFocusArea.individualAreas) {
      selected = WorkoutFocusAreaSelection.toggle(
        selectedAreas: selected,
        area: area,
      );
    }

    expect(
      WorkoutFocusArea.individualAreas.every(selected.contains),
      isTrue,
    );
    expect(selected, contains(WorkoutFocusArea.fullBody));
  });

  test('deselecting full_body clears the full selection', () {
    final selected = WorkoutFocusAreaSelection.toggle(
      selectedAreas: {
        WorkoutFocusArea.fullBody,
        ...WorkoutFocusArea.individualAreas,
      },
      area: WorkoutFocusArea.fullBody,
    );

    expect(selected, isEmpty);
  });
}

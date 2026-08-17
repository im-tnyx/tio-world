enum WorkoutFocusArea {
  fullBody('full_body'),
  shoulders('shoulders'),
  arms('arms'),
  back('back'),
  chest('chest'),
  abs('abs'),
  glutes('glutes'),
  legs('legs'),
  cardio('cardio');

  const WorkoutFocusArea(this.storageValue);

  final String storageValue;

  static const individualAreas = <WorkoutFocusArea>{
    WorkoutFocusArea.shoulders,
    WorkoutFocusArea.arms,
    WorkoutFocusArea.back,
    WorkoutFocusArea.chest,
    WorkoutFocusArea.abs,
    WorkoutFocusArea.glutes,
    WorkoutFocusArea.legs,
    WorkoutFocusArea.cardio,
  };

  static WorkoutFocusArea? fromStorageValue(String? value) {
    for (final area in WorkoutFocusArea.values) {
      if (area.storageValue == value) return area;
    }
    return null;
  }
}

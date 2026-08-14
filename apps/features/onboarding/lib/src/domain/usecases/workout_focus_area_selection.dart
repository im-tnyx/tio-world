import '../models/models.dart';

class WorkoutFocusAreaSelection {
  const WorkoutFocusAreaSelection._();

  static Set<WorkoutFocusArea> toggle({
    required Set<WorkoutFocusArea> selectedAreas,
    required WorkoutFocusArea area,
  }) {
    final next = {...selectedAreas};

    if (area == WorkoutFocusArea.fullBody) {
      if (next.contains(WorkoutFocusArea.fullBody)) {
        next.clear();
      } else {
        next
          ..clear()
          ..add(WorkoutFocusArea.fullBody)
          ..addAll(WorkoutFocusArea.individualAreas);
      }
      return next;
    }

    if (!next.remove(area)) {
      next.add(area);
    }

    if (next.contains(WorkoutFocusArea.fullBody) &&
        !WorkoutFocusArea.individualAreas.every(next.contains)) {
      next.remove(WorkoutFocusArea.fullBody);
    }

    if (WorkoutFocusArea.individualAreas.every(next.contains)) {
      next.add(WorkoutFocusArea.fullBody);
    } else {
      next.remove(WorkoutFocusArea.fullBody);
    }

    return next;
  }
}

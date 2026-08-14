import '../../domain/models/targets_setup_data.dart';

/// Maps domain [TargetsSetupData] into the verified Tnyx backend DTO schema.
class TargetsSetupDtoMapper {
  const TargetsSetupDtoMapper();

  Map<String, dynamic> toRequestPayload(
    TargetsSetupData data, {
    double? fallbackTargetWeightKg,
  }) {
    final sleepHours = data.sleepTargetMinutes / 60.0;

    return <String, dynamic>{
      'stepTarget': data.dailySteps,
      'sleepTarget': sleepHours,
      'sleepTime': formatMinutesToHHMM(data.sleepTimeMinutes),
      'wakeTime': formatMinutesToHHMM(data.wakeTimeMinutes),
      'waterTarget': data.waterMl,
      'goalPaceKgPerWeek': data.goalPaceKgPerWeek,
      'targetWeight': fallbackTargetWeightKg ?? 60.0,
    };
  }

  static String formatMinutesToHHMM(int totalMinutes) {
    final normalized = totalMinutes % (24 * 60);
    final hours = normalized ~/ 60;
    final minutes = normalized % 60;
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

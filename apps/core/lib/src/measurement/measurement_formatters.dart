import 'measurement_converters.dart';
import 'measurement_units.dart';

class MeasurementFormatters {
  const MeasurementFormatters._();

  static String formatWeight(
    double kilograms,
    WeightUnit unit, {
    int decimals = 1,
  }) {
    final value = unit == WeightUnit.kg
        ? kilograms
        : MeasurementConverters.kgToLb(kilograms);
    final suffix = unit == WeightUnit.kg ? 'kg' : 'lb';
    return '${_trimFixed(value, decimals)} $suffix';
  }

  static String formatHeight(double centimetres, HeightUnit unit) {
    if (unit == HeightUnit.ftIn) {
      final result = MeasurementConverters.cmToFeetInches(centimetres);
      return '${result.feet} ft ${result.inches} in';
    }
    return '${_trimFixed(centimetres, 2)} cm';
  }

  static String formatDistance(
    double kilometres,
    DistanceUnit unit, {
    int decimals = 2,
  }) {
    final value = unit == DistanceUnit.km
        ? kilometres
        : MeasurementConverters.kmToMi(kilometres);
    final suffix = unit == DistanceUnit.km ? 'km' : 'mi';
    return '${_trimFixed(value, decimals)} $suffix';
  }

  static String formatVolume(
    double millilitres,
    VolumeUnit unit, {
    int decimals = 1,
  }) {
    if (unit == VolumeUnit.flOz) {
      return '${_trimFixed(MeasurementConverters.mlToFlOz(millilitres), decimals)} fl oz';
    }
    if (millilitres >= 1000) {
      return '${_trimFixed(millilitres / 1000, decimals)} L';
    }
    return '${_trimFixed(millilitres, 0)} mL';
  }

  static String _trimFixed(double value, int decimals) {
    if (decimals <= 0) return value.round().toString();
    var text = value.toStringAsFixed(decimals);
    while (text.contains('.') && text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }
}

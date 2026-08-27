class UnitConverters {
  const UnitConverters._();

  static const double poundsPerKilogram = 2.2046226218487757;
  static const double centimetresPerInch = 2.54;
  static const double milesPerKilometre = 0.621371192237334;
  static const double usFluidOuncesPerMillilitre = 0.033814022701843;

  static double kgToLb(double kilograms) => kilograms * poundsPerKilogram;
  static double lbToKg(double pounds) => pounds / poundsPerKilogram;

  static double cmToTotalInches(double centimetres) =>
      centimetres / centimetresPerInch;
  static double totalInchesToCm(double inches) => inches * centimetresPerInch;

  static ({int feet, int inches}) cmToFeetInches(double centimetres) {
    final totalInches = cmToTotalInches(centimetres).round();
    return (feet: totalInches ~/ 12, inches: totalInches % 12);
  }

  static double feetInchesToCm({required int feet, required int inches}) =>
      totalInchesToCm((feet * 12) + inches.toDouble());

  static double kmToMi(double kilometres) => kilometres * milesPerKilometre;
  static double miToKm(double miles) => miles / milesPerKilometre;

  static double mlToFlOz(double millilitres) =>
      millilitres * usFluidOuncesPerMillilitre;
  static double flOzToMl(double fluidOunces) =>
      fluidOunces / usFluidOuncesPerMillilitre;
}

/// Temporary migration bridge while repository-wide consumers move to
/// [UnitConverters]. Issue #23 requires removal before final acceptance.
@Deprecated('Use UnitConverters')
class MeasurementConverters {
  const MeasurementConverters._();

  static const double poundsPerKilogram = UnitConverters.poundsPerKilogram;
  static const double centimetresPerInch = UnitConverters.centimetresPerInch;
  static const double milesPerKilometre = UnitConverters.milesPerKilometre;
  static const double usFluidOuncesPerMillilitre =
      UnitConverters.usFluidOuncesPerMillilitre;

  static double kgToLb(double kilograms) => UnitConverters.kgToLb(kilograms);
  static double lbToKg(double pounds) => UnitConverters.lbToKg(pounds);

  static double cmToTotalInches(double centimetres) =>
      UnitConverters.cmToTotalInches(centimetres);
  static double totalInchesToCm(double inches) =>
      UnitConverters.totalInchesToCm(inches);

  static ({int feet, int inches}) cmToFeetInches(double centimetres) =>
      UnitConverters.cmToFeetInches(centimetres);

  static double feetInchesToCm({required int feet, required int inches}) =>
      UnitConverters.feetInchesToCm(feet: feet, inches: inches);

  static double kmToMi(double kilometres) => UnitConverters.kmToMi(kilometres);
  static double miToKm(double miles) => UnitConverters.miToKm(miles);

  static double mlToFlOz(double millilitres) =>
      UnitConverters.mlToFlOz(millilitres);
  static double flOzToMl(double fluidOunces) =>
      UnitConverters.flOzToMl(fluidOunces);
}

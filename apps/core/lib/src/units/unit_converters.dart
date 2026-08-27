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

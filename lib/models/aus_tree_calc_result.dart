/// Result for a single section under one wind scenario.
///
/// Units:
/// - qPa: wind pressure (Pa)
/// - windForceN: total wind force on crown (N)
/// - bendingMomentNm: Nm
/// - bendingStressMPa: MPa
class AusTreeCalcResult {
  final double qPa;
  final double windForceN;
  final double bendingMomentNm;
  final double bendingStressMPa;
  final double safetyFactor;

  const AusTreeCalcResult({
    required this.qPa,
    required this.windForceN,
    required this.bendingMomentNm,
    required this.bendingStressMPa,
    required this.safetyFactor,
  });
}

import 'dart:math' as math;

import '../models/aus_tree_calc_result.dart';
import '../models/species_preset.dart';

/// Builds a textual breakdown of the base statics calculations
/// (formulas plus numeric substitution) for a single scenario.
class CalculationBreakdownBuilder {
  static const double _airDensity = 1.2; // kg/m³

  /// Returns a multi-line string describing formulas and substituted
  /// values used for the current calculation.
  static String buildBreakdown({
    required SpeciesPreset species,
    required double dbhCm,
    required double heightM,
    required double crownDiameterM,
    double? cavityInnerDiameterCm,
    required double designWindSpeedMs,
    double? crownFullnessOverride,
    required double siteFactor,
    required AusTreeCalcResult result,
    double defectStrengthFactor = 1.0,
  }) {
    final buffer = StringBuffer();

    final dbhM = dbhCm / 100.0;
    double dOuter = dbhM;
    double dInner = 0.0;
    if (cavityInnerDiameterCm != null && cavityInnerDiameterCm > 0) {
      double cav = cavityInnerDiameterCm;
      if (cav >= dbhCm) {
        cav = dbhCm * 0.99;
      }
      dInner = cav / 100.0;
    }

    final V = designWindSpeedMs;
    final q = siteFactor * 0.5 * _airDensity * V * V; // Pa

    final radiusCrown = crownDiameterM / 2.0;
    final aPlan = math.pi * radiusCrown * radiusCrown; // m²

    final baseFullness = crownFullnessOverride ?? species.defaultFullness;
    final fullness = baseFullness.clamp(0.1, 1.0);
    final projectedArea = aPlan * species.crownShapeFactor * fullness; // m²

    final windForce = q * species.dragCoefficient * projectedArea; // N

    final hEff = 0.66 * heightM; // m
    final mWind = windForce * hEff; // Nm

    final double W;
    if (dInner > 0) {
      W = math.pi * (math.pow(dOuter, 4) - math.pow(dInner, 4)) /
          (32.0 * dOuter);
    } else {
      W = math.pi * math.pow(dOuter, 3) / 32.0;
    }

    final sigmaPa = mWind / W;
    final sigmaMPa = sigmaPa / 1e6;

    buffer.writeln('Base formulas (SI units)');
    buffer.writeln(
        '1) Wind pressure at canopy height:  q = siteFactor × 0.5 × ρ × V²');
    buffer.writeln(
        '2) Crown plan area (circle):       A_plan = π × (D_crown / 2)²');
    buffer.writeln(
        '3) Crown projected area:           A = A_plan × kA × fullness');
    buffer.writeln(
        '4) Wind force on crown:            F_wind = q × C_d × A');
    buffer.writeln(
        '5) Effective height of load:       h_eff = 0.66 × H');
    buffer.writeln(
        '6) Bending moment at base:         M_wind = F_wind × h_eff');
    buffer.writeln(
        '7) Section modulus (solid):        W_solid = π × d³ / 32');
    buffer.writeln(
        '   Section modulus (hollow):       W_hollow = π × (d⁴ − d_i⁴) / (32 × d)');
    buffer.writeln(
        '8) Bending stress:                 σ = M_wind / W');
    buffer.writeln(
        '9) Safety factor:                  SF = f_b,green / σ_MPa');
    buffer.writeln();

    buffer.writeln('Substituted values for this tree');
    buffer.writeln(
        '- DBH (outer diameter at assessment height): d = ${dbhM.toStringAsFixed(3)} m');
    if (dInner > 0) {
      buffer.writeln(
          '- Cavity inner diameter:           d_i = ${dInner.toStringAsFixed(3)} m');
    } else {
      buffer.writeln('- Cavity inner diameter:           d_i = 0 m (solid section)');
    }
    buffer.writeln('- Height:                          H = ${heightM.toStringAsFixed(2)} m');
    buffer.writeln(
        '- Crown diameter:                   D_crown = ${crownDiameterM.toStringAsFixed(2)} m');
    buffer.writeln(
        '- Design gust wind speed:           V = ${V.toStringAsFixed(1)} m/s');
    buffer.writeln('- Site factor:                      siteFactor = ${siteFactor.toStringAsFixed(2)}');
    final effectiveFbMPa = species.fbGreenMPa * defectStrengthFactor;
    buffer.writeln(
        '- Green bending strength (species-group): f_b,green = ${species.fbGreenMPa.toStringAsFixed(1)} MPa');
    buffer.writeln(
        '- Defect strength factor (dimensionless):  k_defect = ${defectStrengthFactor.toStringAsFixed(2)}');
    buffer.writeln(
        '- Effective bending strength used:         f_b,eff = ${effectiveFbMPa.toStringAsFixed(1)} MPa');
    buffer.writeln(
        '- Drag coefficient:                 C_d = ${species.dragCoefficient.toStringAsFixed(2)}');
    buffer.writeln(
        '- Crown shape factor:               kA = ${species.crownShapeFactor.toStringAsFixed(2)}');
    buffer.writeln(
        '- Effective crown fullness:         fullness = ${fullness.toStringAsFixed(2)}');
    buffer.writeln();

    buffer.writeln('Calculated intermediate values');
    buffer.writeln(
        'q = siteFactor × 0.5 × ρ × V² = ${siteFactor.toStringAsFixed(2)} × 0.5 × '
        '${_airDensity.toStringAsFixed(1)} × ${V.toStringAsFixed(1)}² ≈ '
        '${q.toStringAsFixed(0)} Pa');
    buffer.writeln(
        'A_plan = π × (D_crown / 2)² = π × (${crownDiameterM.toStringAsFixed(2)} / 2)² '
        '≈ ${aPlan.toStringAsFixed(2)} m²');
    buffer.writeln(
        'A = A_plan × kA × fullness = ${aPlan.toStringAsFixed(2)} × '
        '${species.crownShapeFactor.toStringAsFixed(2)} × ${fullness.toStringAsFixed(2)} '
        '≈ ${projectedArea.toStringAsFixed(2)} m²');
    buffer.writeln(
        'F_wind = q × C_d × A ≈ ${q.toStringAsFixed(0)} × '
        '${species.dragCoefficient.toStringAsFixed(2)} × '
        '${projectedArea.toStringAsFixed(2)} ≈ ${windForce.toStringAsFixed(0)} N');
    buffer.writeln(
        'h_eff = 0.66 × H = 0.66 × ${heightM.toStringAsFixed(2)} ≈ '
        '${hEff.toStringAsFixed(2)} m');
    buffer.writeln(
        'M_wind = F_wind × h_eff ≈ ${windForce.toStringAsFixed(0)} × '
        '${hEff.toStringAsFixed(2)} ≈ ${mWind.toStringAsFixed(0)} Nm');

    if (dInner > 0) {
      buffer.writeln(
          'W = π × (d⁴ − d_i⁴) / (32 × d) ≈ π × '
          '(${dOuter.toStringAsFixed(3)}⁴ − ${dInner.toStringAsFixed(3)}⁴) / '
          '(32 × ${dOuter.toStringAsFixed(3)}) ≈ ${W.toStringAsExponential(3)} m³');
    } else {
      buffer.writeln(
          'W = π × d³ / 32 ≈ π × ${dOuter.toStringAsFixed(3)}³ / 32 '
          '≈ ${W.toStringAsExponential(3)} m³');
    }

    buffer.writeln(
        'σ = M_wind / W ≈ ${mWind.toStringAsFixed(0)} / '
        '${W.toStringAsExponential(3)} ≈ ${sigmaPa.toStringAsExponential(3)} Pa '
        '≈ ${sigmaMPa.toStringAsFixed(2)} MPa');
    buffer.writeln(
        'SF = f_b,eff / σ_MPa ≈ '
        '${effectiveFbMPa.toStringAsFixed(1)} / ${sigmaMPa.toStringAsFixed(2)} '
        '≈ ${result.safetyFactor.isFinite ? result.safetyFactor.toStringAsFixed(2) : 'very high'}');

    return buffer.toString();
  }
}

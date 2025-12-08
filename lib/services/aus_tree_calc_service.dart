import 'dart:math' as math;

import '../models/aus_tree_calc_result.dart';
import '../models/pruning_scenario_result.dart';
import '../models/species_preset.dart';
import '../models/validation_issue.dart';

/// Core AusTreeCalc statics engine and validation utilities.
///
/// All methods are pure and deterministic.
class AusTreeCalcService {
  static const double _airDensity = 1.2; // kg/m³

  /// Validates user inputs and returns a list of issues.
  ///
  /// Units:
  /// - dbhCm, cavityInnerDiameterCm in cm
  /// - heightM, crownDiameterM in m
  /// - designWindSpeedMs in m/s
  static List<ValidationIssue> validateInputs({
    required double? dbhCm,
    required double? heightM,
    required double? crownDiameterM,
    required double? designWindSpeedMs,
    required double? cavityInnerDiameterCm,
  }) {
    final issues = <ValidationIssue>[];

    if (dbhCm == null || dbhCm <= 0) {
      issues.add(const ValidationIssue(
        message: 'DBH must be greater than zero.',
        isError: true,
      ));
    }
    if (heightM == null || heightM <= 0) {
      issues.add(const ValidationIssue(
        message: 'Height must be greater than zero.',
        isError: true,
      ));
    }
    if (crownDiameterM == null || crownDiameterM <= 0) {
      issues.add(const ValidationIssue(
        message: 'Crown diameter must be greater than zero.',
        isError: true,
      ));
    }
    if (designWindSpeedMs == null || designWindSpeedMs <= 0) {
      issues.add(const ValidationIssue(
        message: 'Design wind speed must be greater than zero.',
        isError: true,
      ));
    }

    if (designWindSpeedMs != null && designWindSpeedMs > 80) {
      issues.add(const ValidationIssue(
        message:
            'Design wind speed above 80 m/s (~288 km/h) is likely unrealistic for most sites.',
        isError: false,
      ));
    }

    if (cavityInnerDiameterCm != null && cavityInnerDiameterCm < 0) {
      issues.add(const ValidationIssue(
        message:
            'Cavity inner diameter cannot be negative. It will be treated as zero.',
        isError: false,
      ));
    }

    if (dbhCm != null &&
        dbhCm > 0 &&
        cavityInnerDiameterCm != null &&
        cavityInnerDiameterCm >= dbhCm) {
      issues.add(const ValidationIssue(
        message:
            'Cavity inner diameter is equal to or greater than DBH. It will be capped at 99% of DBH for calculations.',
        isError: false,
      ));
    }

    if (dbhCm != null &&
        heightM != null &&
        heightM > 0 &&
        heightM < 2 * (dbhCm / 100.0)) {
      issues.add(const ValidationIssue(
        message:
            'Height is very low relative to stem diameter; geometry may be atypical.',
        isError: false,
      ));
    }

    if (heightM != null &&
        crownDiameterM != null &&
        crownDiameterM > 2 * heightM) {
      issues.add(const ValidationIssue(
        message:
            'Crown diameter is very large relative to height; check measurements.',
        isError: false,
      ));
    }

    return issues;
  }

  /// Core statics calculation for a single tree / section.
  ///
  /// Units:
  /// - dbhCm, cavityInnerDiameterCm in cm
  /// - heightM, crownDiameterM in m
  /// - designWindSpeedMs in m/s
  static AusTreeCalcResult calculateSingle({
    required SpeciesPreset species,
    required double dbhCm,
    required double heightM,
    required double crownDiameterM,
    required double designWindSpeedMs,
    double? cavityInnerDiameterCm,
    double? crownFullnessOverride,
    double siteFactor = 1.0,
    double defectStrengthFactor = 1.0,
  }) {
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
    final aPlan = math.pi * radiusCrown * radiusCrown;

    final baseFullness = crownFullnessOverride ?? species.defaultFullness;
    final fullness = baseFullness.clamp(0.1, 1.0);
    final area = aPlan * species.crownShapeFactor * fullness;

    final windForce = q * species.dragCoefficient * area; // N
    final hEff = 0.66 * heightM;
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

    // Effective green bending strength after accounting for observed
    // structural defects/decay via a simple reduction factor.
    final effectiveFb = species.fbGreenMPa * defectStrengthFactor;

    final safetyFactor =
        sigmaMPa > 0 ? effectiveFb / sigmaMPa : double.infinity;

    return AusTreeCalcResult(
      qPa: q,
      windForceN: windForce,
      bendingMomentNm: mWind,
      bendingStressMPa: sigmaMPa,
      safetyFactor: safetyFactor,
    );
  }

  /// Estimates the wind speed at which SF ≈ 1 for the same geometry.
  ///
  /// Uses SF ∝ 1 / V². If SF_design = sfD at V_design,
  /// then V_failure ≈ V_design * sqrt(sfD).
  static double? estimateWindToFailure({
    required SpeciesPreset species,
    required double dbhCm,
    required double heightM,
    required double crownDiameterM,
    required double designWindSpeedMs,
    double? cavityInnerDiameterCm,
    double? crownFullnessOverride,
    double siteFactor = 1.0,
    double defectStrengthFactor = 1.0,
  }) {
    final ref = calculateSingle(
      species: species,
      dbhCm: dbhCm,
      heightM: heightM,
      crownDiameterM: crownDiameterM,
      designWindSpeedMs: designWindSpeedMs,
      cavityInnerDiameterCm: cavityInnerDiameterCm,
      crownFullnessOverride: crownFullnessOverride,
      siteFactor: siteFactor,
      defectStrengthFactor: defectStrengthFactor,
    );

    final sf = ref.safetyFactor;
    if (!sf.isFinite || sf <= 0) return null;
    return designWindSpeedMs * math.sqrt(sf);
  }

  /// Pruning / crown reduction before/after.
  static PruningScenarioResult calculatePruningScenario({
    required SpeciesPreset species,
    required double dbhCm,
    required double heightM,
    required double crownDiameterM,
    required double designWindSpeedMs,
    double? cavityInnerDiameterCm,
    double? crownFullnessOverride,
    double siteFactor = 1.0,
    double defectStrengthFactor = 1.0,
    required double crownDiameterReductionPercent,
    required double fullnessReductionPercent,
  }) {
    final baseFullness = (crownFullnessOverride ?? species.defaultFullness)
        .clamp(0.1, 1.0);

    final before = calculateSingle(
      species: species,
      dbhCm: dbhCm,
      heightM: heightM,
      crownDiameterM: crownDiameterM,
      designWindSpeedMs: designWindSpeedMs,
      cavityInnerDiameterCm: cavityInnerDiameterCm,
      crownFullnessOverride: baseFullness,
      siteFactor: siteFactor,
      defectStrengthFactor: defectStrengthFactor,
    );

    final crownAfter =
        crownDiameterM * (1.0 - crownDiameterReductionPercent / 100.0);
    final fullnessAfterRaw =
        baseFullness * (1.0 - fullnessReductionPercent / 100.0);
    final fullnessAfter = fullnessAfterRaw.clamp(0.1, 1.0);

    final after = calculateSingle(
      species: species,
      dbhCm: dbhCm,
      heightM: heightM,
      crownDiameterM: crownAfter,
      designWindSpeedMs: designWindSpeedMs,
      cavityInnerDiameterCm: cavityInnerDiameterCm,
      crownFullnessOverride: fullnessAfter,
      siteFactor: siteFactor,
      defectStrengthFactor: defectStrengthFactor,
    );

    return PruningScenarioResult(
      before: before,
      after: after,
      crownDiameterBeforeM: crownDiameterM,
      crownDiameterAfterM: crownAfter,
      fullnessBefore: baseFullness,
      fullnessAfter: fullnessAfter,
    );
  }

  static List<ValidationIssue> postCalculationWarnings(
    AusTreeCalcResult result,
  ) {
    final issues = <ValidationIssue>[];
    if (result.safetyFactor > 5.0 && result.safetyFactor.isFinite) {
      issues.add(const ValidationIssue(
        message:
            'Unusually high safety factor; check that inputs and presets are realistic.',
        isError: false,
      ));
    }
    return issues;
  }
}

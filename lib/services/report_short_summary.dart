import 'as4970_language.dart';
import '../models/aus_tree_calc_result.dart';

/// Generates a short, planning-ready AS 4970-aligned summary.
class ShortSummaryGenerator {
  static String buildShortSummary({
    required String treeLabel,
    required String speciesLabel,
    required String governingSectionLabel,
    required double designWindSpeedMs,
    required AusTreeCalcResult governingSectionResult,
    double? windToFailureMs,
    String? siteLocation,
    String? defectSummary,
  }) {
    final sf = governingSectionResult.safetyFactor;
    final sfText =
        sf.isFinite ? sf.toStringAsFixed(2) : 'very high (modelled upper bound)';
    final sfInterp = As4970Language.interpretSafetyFactorRange(sf);
    final windQual = As4970Language.windToFailureQualitative(
      designWindSpeedMs,
      windToFailureMs,
    );

    final buffer = StringBuffer();

    if (siteLocation != null && siteLocation.trim().isNotEmpty) {
      buffer.write(
          'For $treeLabel ($speciesLabel) at $siteLocation, the governing structural section is ');
    } else {
      buffer.write(
          'For $treeLabel ($speciesLabel), the governing structural section is ');
    }

    buffer.write(
        '$governingSectionLabel, which controls the overall structural condition under '
        'wind loading. The modelled safety factor at a design gust of '
        '${designWindSpeedMs.toStringAsFixed(1)} m/s is $sfText. $sfInterp ');

    if (defectSummary != null && defectSummary.trim().isNotEmpty) {
      buffer.write(
          'Observed structural defects and decay indicators include: $defectSummary ');
    }

    buffer.write(
        'The estimated wind-to-failure threshold (SF ≈ 1) is used as decision context '
        'rather than a prediction of failure; $windQual '
        'These results are provided as decision-support modelling within the AS 4970 '
        'framework to inform, rather than replace, professional arboricultural judgement.');

    return buffer.toString();
  }
}

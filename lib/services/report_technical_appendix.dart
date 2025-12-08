import 'as4970_language.dart';
import '../models/aus_tree_calc_result.dart';
import '../models/pruning_scenario_result.dart';

/// Builds a full technical appendix aligned with AS 4970:2025.
class TechnicalAppendixBuilder {
  static String buildTechnicalAppendix({
    required String treeLabel,
    required String speciesLabel,
    required String governingSectionLabel,
    required double dbhCm,
    required double heightM,
    required double crownDiameterM,
    double? cavityInnerDiameterCm,
    required double designWindSpeedMs,
    required AusTreeCalcResult governingSectionResult,
    double? windToFailureMs,
    List<String>? sectionLabels,
    List<AusTreeCalcResult>? sectionResults,
    PruningScenarioResult? pruningScenario,
    String figurePrefix = 'Figure A',
    String? siteLocation,
    String? defectSummary,
    String? baseCalculationText,
  }) {
    final headings = As4970Language.technicalAppendixHeadings();
    final buffer = StringBuffer();
    final sf = governingSectionResult.safetyFactor;

    // 1. Assessment Framework and AS 4970 Alignment
    buffer.writeln(headings[0]);
    buffer.writeln(
        'This technical appendix documents decision-support modelling undertaken for '
        '$treeLabel in the context of AS 4970:2025 – Protection of Trees on Development '
        'Sites. The modelling provides a simplified statics-based view of structural '
        'margins under wind loading and is intended to support, rather than replace, '
        'arboricultural judgement and Visual Tree Assessment (VTA).');
    buffer.writeln();
    buffer.writeln(As4970Language.describeSafetyFactorConcept());
    buffer.writeln();

    // 2. Tree Characteristics and Structural Condition
    buffer.writeln(headings[1]);
    buffer.writeln(
        'Tree: $treeLabel ($speciesLabel)');
    if (siteLocation != null && siteLocation.trim().isNotEmpty) {
      buffer.writeln('Location: $siteLocation');
    }
    buffer.writeln(
        'DBH: ${dbhCm.toStringAsFixed(1)} cm\n'
        'Height: ${heightM.toStringAsFixed(1)} m\n'
        'Crown diameter: ${crownDiameterM.toStringAsFixed(1)} m');
    if (cavityInnerDiameterCm != null && cavityInnerDiameterCm > 0) {
      buffer.writeln(
          'Internal cavity at assessment height: '
          '${cavityInnerDiameterCm.toStringAsFixed(1)} cm (major trunk defect modelled).');
    } else {
      buffer.writeln(
          'No significant internal cavity was explicitly modelled at the assessment height.');
    }
    buffer.writeln(
        'The overall structural condition is interpreted through the modelled safety '
        'factor for the governing structural section described below.');
    buffer.writeln();

    // 3. Structural Defects and Stem Sections
    buffer.writeln(headings[2]);
    buffer.writeln(
      As4970Language.describeGoverningSection(
        sectionLabel: governingSectionLabel,
        safetyFactor: sf,
      ),
    );
    if (defectSummary != null && defectSummary.trim().isNotEmpty) {
      buffer.writeln(
          'Observed structural defects and decay indicators at the time of inspection include: '
          '$defectSummary');
    }
    if (sectionLabels != null && sectionResults != null) {
      buffer.writeln(
          'Other stem sections have also been modelled to identify structural defects '
          'and the section with the lowest safety factor (governing defect):');
      for (var i = 0; i < sectionLabels.length; i++) {
        final label = sectionLabels[i];
        final res = sectionResults[i];
        buffer.writeln(
            '- Section $label: SF = '
            '${res.safetyFactor.isFinite ? res.safetyFactor.toStringAsFixed(2) : '∞'}');
      }
    }
    buffer.writeln();

    // 4. Structural Margin Results
    buffer.writeln(headings[3]);
    buffer.writeln(
        'Design gust wind speed at canopy height: '
        '${designWindSpeedMs.toStringAsFixed(1)} m/s.');
    buffer.writeln(
        'Governing section safety factor: '
        '${sf.isFinite ? sf.toStringAsFixed(2) : '∞'}.');
    buffer.writeln(As4970Language.interpretSafetyFactorRange(sf));
    if (baseCalculationText != null && baseCalculationText.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
          'The above structural margin assessment is supported by the following base '
          'calculation breakdown (formulas and numeric substitution for this scenario):');
      buffer.writeln(baseCalculationText.trim());
    }
    buffer.writeln();

    // 5. Wind Sensitivity and Failure Thresholds
    buffer.writeln(headings[4]);
    buffer.writeln(
        As4970Language.describeWindToFailure(windToFailureMs ?? double.nan));
    if (windToFailureMs != null && windToFailureMs.isFinite) {
      buffer.writeln(
          'Estimated wind-to-failure threshold (SF ≈ 1): '
          '${windToFailureMs.toStringAsFixed(1)} m/s.');
      buffer.writeln(
        As4970Language.windToFailureQualitative(
          designWindSpeedMs,
          windToFailureMs,
        ),
      );
    }
    buffer.writeln();

    // 6. Decay Sensitivity Assessment
    buffer.writeln(headings[5]);
    buffer.writeln(As4970Language.decaySensitivityIntro());
    buffer.writeln(
        'Residual wall thickness thresholds are interpreted as follows:\n'
        '- ≥ 40%: tolerable structural condition\n'
        '- 30–40%: marginal structural condition\n'
        '- < 30%: indicative of an unacceptable increase in risk\n'
        'These thresholds are used qualitatively in line with AS 4970 concepts and '
        'do not represent strict compliance limits.');
    buffer.writeln();

    // 7. Effect of Mitigation (Crown Reduction)
    buffer.writeln(headings[6]);
    if (pruningScenario == null) {
      buffer.writeln(
          'No specific crown reduction scenario has been modelled. Tree-sensitive '
          'mitigation consistent with AS 4970 (for example, targeted crown reduction) '
          'may be considered to support retention where risk can be reasonably reduced.');
    } else {
      final sfBefore = pruningScenario.before.safetyFactor;
      final sfAfter = pruningScenario.after.safetyFactor;
      buffer.writeln(
        As4970Language.describeMitigationEffect(
          sfBefore: sfBefore,
          sfAfter: sfAfter,
        ),
      );
    }
    buffer.writeln();

    // 8. Graphical Evidence
    buffer.writeln(headings[7]);
    buffer.writeln(
      As4970Language.describeGraphReference(
        figureId: '${figurePrefix}1',
        title: 'Safety factor versus wind speed for the governing stem section',
      ),
    );
    buffer.writeln(
      As4970Language.describeGraphReference(
        figureId: '${figurePrefix}2',
        title: 'Sensitivity of structural margin to residual wall thickness',
      ),
    );
    buffer.writeln(
      As4970Language.describeGraphReference(
        figureId: '${figurePrefix}3',
        title: 'Structural margin by stem section',
      ),
    );
    buffer.writeln();

    // 9. Conditions, Assumptions and Limitations
    buffer.writeln(headings[8]);
    buffer.writeln(
        'The modelling is based on simplified statics assumptions, treating the stem as a '
        'circular section and applying uniform wind loading to an equivalent crown area. '
        'Species-group strength values are approximate and conservative, and defects are '
        'represented as idealised geometric cavities or reductions in section.\n'
        'AS 4970 does not mandate quantitative calculations, and the present modelling is '
        'provided as supplementary decision-support information only.\n'
        'Results are sensitive to the quality of input data, assumptions about wind regime, '
        'and the representation of decay and defects.');
    buffer.writeln();
    buffer.writeln(As4970Language.standardLimitationsClause);
    buffer.writeln();

    // 10. Overall Interpretation
    buffer.writeln(headings[9]);
    buffer.writeln(
        'Overall, the numerical outputs (safety factors, wind-to-failure estimates and '
        'graphs) are interpreted within the AS 4970 decision-making framework as indicators '
        'of structural condition and potential changes in risk over time. They do not of '
        'themselves determine whether the tree must be removed or retained; rather, they '
        'inform a retention-first approach where retention with mitigation is preferred '
        'where reasonably practicable.\n'
        'Final decisions should remain grounded in professional judgement, VTA findings, '
        'target usage, site context and planning objectives.');
    buffer.writeln();

    // Terminology cross-reference table
    buffer.writeln('Terminology cross-reference (AS 4970 vs AusTreeCalc)');
    buffer.writeln(As4970Language.terminologyCrossReferenceTable());

    return buffer.toString();
  }
}

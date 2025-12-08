/// Centralised AS 4970:2025-aligned language and interpretation utilities.
///
/// This class only provides wording and interpretation helpers.
/// No structural calculations are performed here.
class As4970Language {
  static const String standardLimitationsClause =
      'This assessment is undertaken in general accordance with the decision-making '
      'framework of AS 4970:2025. The modelling outputs are interpretive tools '
      'intended to support arboricultural judgement and are not representations '
      'of compliance by calculation.';

  static String describeSafetyFactorConcept() {
    return 'In this context, the safety factor (SF) is used as a relative indicator of '
        'structural margin, comparing modelled load effects against an estimated '
        'structural capacity for a specified wind scenario. It does not represent a '
        'probability of failure and does not provide any guarantee of tree safety.';
  }

  static String interpretSafetyFactorRange(double sf) {
    if (sf >= 1.5) {
      return 'Adequate structural margin (SF ≥ 1.5) under the modelled wind scenario.';
    } else if (sf >= 1.0) {
      return 'Reduced structural margin (1.0 ≤ SF < 1.5), indicating elevated sensitivity '
          'to wind loading and a narrower margin to failure.';
    } else {
      return 'Unacceptable increase in failure likelihood (SF < 1.0) under the modelled '
          'wind scenario, noting that this is a decision-support indicator rather than '
          'a predictive guarantee.';
    }
  }

  static String safetyFactorRatingLabel(double sf) {
    if (sf >= 1.5) {
      return 'Adequate structural margin';
    } else if (sf >= 1.0) {
      return 'Reduced structural margin';
    } else {
      return 'Unacceptable increase in failure likelihood';
    }
  }

  static String describeWindToFailure(double windToFailureMs) {
    return 'The wind-to-failure estimate represents the approximate wind speed at which '
        'the modelled structural margin would be fully exhausted (SF ≈ 1) under the '
        'simplified statics assumptions used. It should be interpreted as comparative '
        'decision-support information, not as a deterministic prediction of failure.';
  }

  static String windToFailureQualitative(
      double designWindMs, double? windToFailureMs) {
    if (windToFailureMs == null || windToFailureMs.isNaN) {
      return 'The margin between the design wind and the estimated wind-to-failure '
          'could not be reliably resolved and should be treated with caution.';
    }
    final ratio = windToFailureMs / designWindMs;
    if (ratio >= 1.5) {
      return 'The modelling indicates a moderate structural margin to failure above the '
          'selected design wind speed.';
    } else if (ratio >= 1.1) {
      return 'The modelling indicates a relatively narrow margin to failure above the '
          'selected design wind speed, consistent with reduced structural margin.';
    } else {
      return 'The modelling indicates a material increase in failure likelihood close to '
          'the selected design wind speed, with little margin to failure.';
    }
  }

  static String describeGoverningSection({
    required String sectionLabel,
    required double safetyFactor,
  }) {
    final rating = safetyFactorRatingLabel(safetyFactor);
    return 'The governing structural section controlling overall structural condition '
        'under wind loading is $sectionLabel, which is interpreted as $rating '
        'based on the modelled safety factor.';
  }

  static String structuralDefectDescription({
    required String description,
  }) {
    return 'Modelled structural defect: $description. This is treated as a major trunk '
        'defect affecting the load path and structural condition.';
  }

  static String decaySensitivityIntro() {
    return 'Cavity and decay progression have been explored using a sensitivity analysis '
        'to illustrate how potential future loss of residual wall thickness would '
        'influence overall structural condition.';
  }

  static String interpretResidualWallFraction(double fraction) {
    final percent = (fraction * 100).toStringAsFixed(0);
    if (fraction >= 0.4) {
      return '$percent% residual wall thickness – tolerable structural condition within '
          'the limitations of the model.';
    } else if (fraction >= 0.3) {
      return '$percent% residual wall thickness – marginal structural condition with '
          'reduced structural margin.';
    } else {
      return '$percent% residual wall thickness – indicative of an unacceptable increase '
          'in risk, subject to professional judgement and site context.';
    }
  }

  static String describeMitigationEffect({
    required double sfBefore,
    required double sfAfter,
  }) {
    final improvement = (sfBefore > 0 && sfBefore.isFinite && sfAfter.isFinite)
        ? ((sfAfter - sfBefore) / sfBefore) * 100.0
        : double.nan;

    final improvementText = improvement.isFinite
        ? 'an estimated structural margin improvement of '
            '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(0)}%. '
        : 'a modelled improvement in structural margin. ';

    return 'The modelled crown reduction represents tree-sensitive mitigation consistent '
        'with AS 4970 preference for retention where risk can be reasonably reduced. '
        'In this scenario, the safety factor changes from '
        '${sfBefore.isFinite ? sfBefore.toStringAsFixed(2) : '∞'} to '
        '${sfAfter.isFinite ? sfAfter.toStringAsFixed(2) : '∞'}, corresponding to '
        '$improvementText This supports a retention with mitigation outcome, subject to '
        'broader planning and risk considerations.';
  }

  static List<String> technicalAppendixHeadings() {
    return const [
      'Assessment Framework and AS 4970 Alignment',
      'Tree Characteristics and Structural Condition',
      'Structural Defects and Stem Sections',
      'Structural Margin Results',
      'Wind Sensitivity and Failure Thresholds',
      'Decay Sensitivity Assessment',
      'Effect of Mitigation (Crown Reduction)',
      'Graphical Evidence',
      'Conditions, Assumptions and Limitations',
      'Overall Interpretation',
    ];
  }

  static String describeGraphReference({
    required String figureId,
    required String title,
  }) {
    return '$figureId – $title. This figure is provided as supporting technical evidence '
        'for the above interpretation and should be read as decision-support, not as a '
        'standalone conclusion.';
  }

  static String terminologyCrossReferenceTable() {
    return '''
AS 4970 Concept                 | Corresponding AusTreeCalc Output
--------------------------------|-----------------------------------------------
Structural condition           | Safety factor and section results
Structural defect              | Stem section with decay/cavity
Governing defect               | Section with lowest safety factor
Unacceptable increase in risk  | Safety factor trending toward unity (SF → 1)
Retention with mitigation      | Increased SF after crown reduction
Professional judgement         | Interpretation of outputs by the consulting arborist
''';
  }
}

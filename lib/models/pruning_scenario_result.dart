import 'aus_tree_calc_result.dart';

/// Before/after results for a pruning / crown reduction scenario.
class PruningScenarioResult {
  final AusTreeCalcResult before;
  final AusTreeCalcResult after;
  final double crownDiameterBeforeM;
  final double crownDiameterAfterM;
  final double fullnessBefore;
  final double fullnessAfter;

  const PruningScenarioResult({
    required this.before,
    required this.after,
    required this.crownDiameterBeforeM,
    required this.crownDiameterAfterM,
    required this.fullnessBefore,
    required this.fullnessAfter,
  });
}

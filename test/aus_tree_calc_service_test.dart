import 'package:flutter_test/flutter_test.dart';

import 'package:aus_tree_calc/models/species_preset.dart';
import 'package:aus_tree_calc/services/aus_tree_calc_service.dart';
import 'package:aus_tree_calc/services/species_presets.dart';
import 'package:aus_tree_calc/models/validation_issue.dart';

void main() {
  group('AusTreeCalcService core calculations', () {
    final SpeciesPreset eucTypical = SpeciesPresets.eucTypical;

    test('Typical eucalypt has reasonable safety factor range', () {
      final result = AusTreeCalcService.calculateSingle(
        species: eucTypical,
        dbhCm: 50.0,
        heightM: 18.0,
        crownDiameterM: 10.0,
        designWindSpeedMs: 40.0,
      );

      expect(result.safetyFactor, greaterThan(0.5));
      expect(result.safetyFactor, lessThan(10.0));
    });

    test('Hollow stem has lower SF than solid stem', () {
      final solid = AusTreeCalcService.calculateSingle(
        species: eucTypical,
        dbhCm: 60.0,
        heightM: 20.0,
        crownDiameterM: 12.0,
        designWindSpeedMs: 40.0,
      );

      final hollow = AusTreeCalcService.calculateSingle(
        species: eucTypical,
        dbhCm: 60.0,
        heightM: 20.0,
        crownDiameterM: 12.0,
        designWindSpeedMs: 40.0,
        cavityInnerDiameterCm: 40.0,
      );

      expect(hollow.safetyFactor, lessThan(solid.safetyFactor));
    });

    test('Pruning scenario increases safety factor', () {
      final scenario = AusTreeCalcService.calculatePruningScenario(
        species: eucTypical,
        dbhCm: 60.0,
        heightM: 20.0,
        crownDiameterM: 12.0,
        designWindSpeedMs: 40.0,
        crownFullnessOverride: 0.9,
        crownDiameterReductionPercent: 20.0,
        fullnessReductionPercent: 30.0,
      );

      expect(
        scenario.after.safetyFactor,
        greaterThan(scenario.before.safetyFactor),
      );
    });
  });

  group('Validation', () {
    test('Zero or negative DBH flagged as error', () {
      final List<ValidationIssue> issues =
          AusTreeCalcService.validateInputs(
        dbhCm: 0,
        heightM: 10,
        crownDiameterM: 5,
        designWindSpeedMs: 40,
        cavityInnerDiameterCm: 0,
      );

      expect(issues.any((i) => i.isError), isTrue);
    });
  });
}

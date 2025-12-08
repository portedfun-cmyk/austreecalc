import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/aus_tree_calc_result.dart';
import '../models/pruning_scenario_result.dart';
import '../models/species_preset.dart';
import '../models/validation_issue.dart';
import '../models/wind_preset.dart';
import '../services/as4970_language.dart';
import '../services/aus_tree_calc_service.dart';
import '../services/calculation_breakdown.dart';
import '../services/report_short_summary.dart';
import '../services/report_technical_appendix.dart';
import '../services/species_presets.dart';
import '../services/wind_presets.dart';
import 'simulation_graphs.dart';

class AusTreeCalcMainScreen extends StatefulWidget {
  const AusTreeCalcMainScreen({super.key});

  @override
  State<AusTreeCalcMainScreen> createState() => _AusTreeCalcMainScreenState();
}

class _AusTreeCalcMainScreenState extends State<AusTreeCalcMainScreen> {
  SpeciesPreset _selectedSpecies = SpeciesPresets.eucTypical;
  WindPreset _selectedWindPreset = WindPresets.regionBUrban;

  // Tree identity and location
  final TextEditingController _treeLabelController =
      TextEditingController(text: 'Tree 1');
  final TextEditingController _siteLocationController =
      TextEditingController(text: '');

  final TextEditingController _dbhController =
      TextEditingController(text: '50');
  final TextEditingController _heightController =
      TextEditingController(text: '18');
  final TextEditingController _crownDiameterController =
      TextEditingController(text: '10');
  final TextEditingController _cavityController =
      TextEditingController(text: '');
  final TextEditingController _designWindController =
      TextEditingController(text: '40');

  double _siteFactor = 1.0;
  double? _crownFullnessOverride;
  bool _showAdvanced = false;

  bool _simulatePruning = false;
  double _crownDiameterReductionPercent = 20.0;
  double _fullnessReductionPercent = 30.0;

  List<ValidationIssue> _issues = [];
  List<ValidationIssue> _postCalcWarnings = [];
  AusTreeCalcResult? _mainResult;
  PruningScenarioResult? _pruningResult;
  double? _windToFailureMs;

  // Data for SF vs wind speed graph.
  List<double> _sfWindSpeeds = [];
  List<double> _sfWindSafetyFactors = [];

  // Data for SF vs crown reduction percentage.
  List<double> _reductionPercents = [];
  List<double> _reductionSafetyFactors = [];

  // Data for SF vs residual wall percentage (decay progression).
  List<double> _residualWallPercents = [];
  List<double> _residualWallSafetyFactors = [];

  // Data for critical residual wall vs wind speed (decay tolerance).
  List<double> _decayToleranceWindSpeeds = [];
  List<double> _decayToleranceCriticalWalls = [];

  // Wind scenario comparison data.
  Map<String, double> _windScenarioSafetyFactors = {};

  // Defect / decay indicators with detailed options.
  bool _defectBracketFungi = false;
  bool _defectCavityDecay = false;
  bool _defectCracks = false;
  bool _defectBasalDecay = false;
  bool _defectUnion = false;
  final TextEditingController _defectOtherController =
      TextEditingController(text: '');

  // Advanced decay parameters.
  String _decayType = 'unknown'; // unknown, white_rot, brown_rot, soft_rot
  String _decayLocation = 'stem_base'; // stem_base, mid_stem, upper_stem, root_plate
  String _decaySeverity = 'moderate'; // minor, moderate, severe, extensive
  double _estimatedDecayExtentPercent = 20.0; // 0-100% of cross-section affected
  int _fruitingBodyCount = 0; // number of fruiting bodies observed
  String _resonanceTestResult = 'not_done'; // not_done, solid, drum, hollow
  final TextEditingController _decayColumnHeightController =
      TextEditingController(text: '');
  bool _showAdvancedDecay = false;

  String _shortSummary = '';
  String _technicalAppendix = '';
  String _baseCalculationText = '';
  double _decaySimResidualWallPercent = 60.0;
  double? _decayCurrentResidualPercent;
  double? _decayCriticalResidualPercent;
  double? _decayCriticalWallThicknessCm;

  // Root plate analysis variables
  bool _showRootPlateAnalysis = false;
  String _soilType = 'clay_loam'; // sandy, clay, clay_loam, loam, organic, rocky
  String _soilMoisture = 'moist'; // dry, moist, wet, waterlogged
  double _leanAngleDegrees = 0.0;
  bool _recentLeanChange = false;
  bool _heavingCracking = false;
  bool _severedRoots = false;
  double _severedRootsPercent = 0.0;
  bool _rootDecay = false;
  bool _restrictedRootZone = false;
  String _rootZoneRestriction = 'none'; // none, pavement, building, wall, excavation
  final TextEditingController _rootPlateRadiusController = TextEditingController(text: '');
  final TextEditingController _rootPlateDepthController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    _revalidate();
  }

  String _buildDefectSummary() {
    final parts = <String>[];
    if (_defectBracketFungi) {
      parts.add(
          'Bracket fungi present on stem or at base, consistent with potential internal decay activity.');
    }
    if (_defectCavityDecay) {
      parts.add('Cavity with visible decayed wood or advanced decomposition.');
    }
    if (_defectCracks) {
      parts.add('Visible longitudinal cracks or shear planes in the stem.');
    }
    if (_defectBasalDecay) {
      parts.add(
          'Basal or root-plate decay symptoms (e.g. buttress softening, fungal fruiting).');
    }
    if (_defectUnion) {
      parts.add('Included bark or compromised unions affecting load path.');
    }
    final other = _defectOtherController.text.trim();
    if (other.isNotEmpty) {
      parts.add(other);
    }
    return parts.join(' ');
  }

  /// Converts the selected structural defect / decay indicators into a
  /// dimensionless strength reduction factor k_defect applied to the
  /// species-group bending strength. 1.0 means no reduction; lower
  /// values represent reduced effective capacity.
  ///
  /// Mathematical basis:
  /// - Decay type affects residual strength: white rot degrades lignin
  ///   (structural), brown rot degrades cellulose (reduces brittleness).
  /// - Location affects load path criticality: base/root-plate failures
  ///   are catastrophic; upper stem less critical.
  /// - Severity scales the reduction factor.
  /// - Multiple defects compound multiplicatively.
  double _computeDefectStrengthFactor() {
    double k = 1.0;

    // === Basic defect indicators (checkboxes) ===
    // Base reduction factors for observed defect types.
    
    // Bracket fungi: indicates active decay. Factor depends on fruiting body count.
    if (_defectBracketFungi) {
      // More fruiting bodies = more extensive decay
      final fungiK = _fruitingBodyCount <= 1
          ? 0.85
          : _fruitingBodyCount <= 3
              ? 0.75
              : _fruitingBodyCount <= 5
                  ? 0.65
                  : 0.55;
      k *= fungiK;
    }
    
    // Cavity with visible decay: already accounted in geometry but
    // decay margin around cavity degrades remaining wood.
    if (_defectCavityDecay) {
      k *= 0.80;
    }
    
    // Longitudinal cracks / shear planes: reduces shear resistance
    // and can propagate under load.
    if (_defectCracks) {
      k *= 0.85;
    }
    
    // Basal/root-plate decay: critical location, high consequence.
    if (_defectBasalDecay) {
      k *= 0.75;
    }
    
    // Included bark / compromised unions: stress concentration
    // and potential failure initiation point.
    if (_defectUnion) {
      k *= 0.85;
    }

    // === Advanced decay parameters ===
    
    // Decay type factor: different rot types have different effects.
    // White rot: degrades lignin, reduces strength significantly.
    // Brown rot: degrades cellulose, wood becomes brittle.
    // Soft rot: surface decay, less structural impact unless extensive.
    double decayTypeFactor = 1.0;
    switch (_decayType) {
      case 'white_rot':
        decayTypeFactor = 0.85; // significant strength loss
        break;
      case 'brown_rot':
        decayTypeFactor = 0.80; // brittle failure risk
        break;
      case 'soft_rot':
        decayTypeFactor = 0.90; // surface effect mainly
        break;
      default:
        decayTypeFactor = 0.90; // unknown = assume moderate
    }
    
    // Only apply decay type factor if decay is indicated
    if (_defectBracketFungi || _defectCavityDecay || _defectBasalDecay) {
      k *= decayTypeFactor;
    }
    
    // Location factor: criticality depends on position in load path.
    // Root plate and stem base are most critical.
    double locationFactor = 1.0;
    switch (_decayLocation) {
      case 'root_plate':
        locationFactor = 0.85; // most critical - whole tree depends on this
        break;
      case 'stem_base':
        locationFactor = 0.90; // high bending moment at base
        break;
      case 'mid_stem':
        locationFactor = 0.95; // moderate criticality
        break;
      case 'upper_stem':
        locationFactor = 1.0; // less critical for main stem failure
        break;
    }
    
    if (_defectBracketFungi || _defectCavityDecay || _defectBasalDecay) {
      k *= locationFactor;
    }
    
    // Severity factor: scales the overall decay impact.
    // Based on estimated proportion of cross-section affected.
    double severityFactor = 1.0;
    switch (_decaySeverity) {
      case 'minor':
        severityFactor = 0.95; // <10% affected
        break;
      case 'moderate':
        severityFactor = 0.85; // 10-30% affected
        break;
      case 'severe':
        severityFactor = 0.70; // 30-50% affected
        break;
      case 'extensive':
        severityFactor = 0.50; // >50% affected
        break;
    }
    
    if (_defectBracketFungi || _defectCavityDecay || _defectBasalDecay) {
      k *= severityFactor;
    }
    
    // Estimated decay extent: direct percentage reduction.
    // This models the loss of effective cross-section due to
    // compromised wood around the cavity.
    // k_extent = 1 - (extent% / 100) * 0.5
    // (50% extent doesn't mean 50% strength loss due to hollow section math)
    if (_estimatedDecayExtentPercent > 0) {
      final extentFactor = 1.0 - (_estimatedDecayExtentPercent / 100.0) * 0.4;
      k *= extentFactor.clamp(0.4, 1.0);
    }
    
    // Resonance test result: acoustic testing indicator.
    switch (_resonanceTestResult) {
      case 'solid':
        // No additional reduction - wood sounds solid
        break;
      case 'drum':
        k *= 0.90; // Some internal degradation
        break;
      case 'hollow':
        k *= 0.75; // Significant internal cavity/decay
        break;
      default:
        // not_done - no additional factor
        break;
    }
    
    // Decay column height: if specified, apply height-based reduction.
    // Taller decay columns are more structurally significant.
    final colHeight = double.tryParse(_decayColumnHeightController.text.trim());
    if (colHeight != null && colHeight > 0) {
      final treeHeight = _parseNullable(_heightController) ?? 15.0;
      final heightRatio = (colHeight / treeHeight).clamp(0.0, 1.0);
      // Column height as fraction of tree height affects moment arm
      final colFactor = 1.0 - heightRatio * 0.3;
      k *= colFactor.clamp(0.5, 1.0);
    }

    // Prevent unrealistically low or >1 values.
    const double minK = 0.20; // At minimum, 20% of original strength
    if (k < minK) {
      k = minK;
    }
    if (k > 1.0) {
      k = 1.0;
    }
    return k;
  }

  /// Calculates a root plate stability factor based on soil conditions,
  /// lean angle, root damage, and other root-zone factors.
  /// Returns a value 0.0-1.0 where 1.0 = stable, lower = higher risk.
  double _computeRootPlateStabilityFactor() {
    if (!_showRootPlateAnalysis) return 1.0;
    
    double factor = 1.0;
    
    // Soil type factor - affects anchorage capacity
    switch (_soilType) {
      case 'rocky':
        factor *= 1.1; // Rock provides excellent anchorage
        break;
      case 'clay':
        factor *= 0.95; // Good when dry, poor when wet
        break;
      case 'clay_loam':
        factor *= 1.0; // Balanced
        break;
      case 'loam':
        factor *= 0.95; // Good general soil
        break;
      case 'sandy':
        factor *= 0.85; // Poor anchorage, prone to erosion
        break;
      case 'organic':
        factor *= 0.75; // Soft, compressible, poor anchorage
        break;
    }
    
    // Soil moisture factor - wet soil reduces anchorage
    switch (_soilMoisture) {
      case 'dry':
        factor *= 1.05; // Slightly better anchorage
        break;
      case 'moist':
        factor *= 1.0; // Normal
        break;
      case 'wet':
        factor *= 0.85; // Reduced anchorage
        break;
      case 'waterlogged':
        factor *= 0.65; // Significantly reduced anchorage
        break;
    }
    
    // Lean angle factor - trees with significant lean are at higher risk
    if (_leanAngleDegrees > 0) {
      // Progressive reduction: 5° = minor, 10° = moderate, 15°+ = severe
      if (_leanAngleDegrees <= 5) {
        factor *= 0.95;
      } else if (_leanAngleDegrees <= 10) {
        factor *= 0.85;
      } else if (_leanAngleDegrees <= 15) {
        factor *= 0.70;
      } else {
        factor *= 0.50; // Severe lean - high risk
      }
    }
    
    // Recent lean change indicates active movement
    if (_recentLeanChange) {
      factor *= 0.70;
    }
    
    // Heaving/cracking around base indicates root plate failure
    if (_heavingCracking) {
      factor *= 0.60;
    }
    
    // Severed roots reduce anchorage proportionally
    if (_severedRoots && _severedRootsPercent > 0) {
      // Each 10% of roots severed = ~8% reduction in stability
      final rootLoss = (_severedRootsPercent / 100.0) * 0.8;
      factor *= (1.0 - rootLoss).clamp(0.3, 1.0);
    }
    
    // Root decay reduces root plate integrity
    if (_rootDecay) {
      factor *= 0.75;
    }
    
    // Restricted root zone limits root development
    if (_restrictedRootZone) {
      switch (_rootZoneRestriction) {
        case 'pavement':
          factor *= 0.85;
          break;
        case 'building':
          factor *= 0.75;
          break;
        case 'wall':
          factor *= 0.80;
          break;
        case 'excavation':
          factor *= 0.65; // Recent excavation is most damaging
          break;
      }
    }
    
    // Root plate dimensions factor (if provided)
    final dbh = _parseNullable(_dbhController);
    final rootRadius = _parseNullable(_rootPlateRadiusController);
    final rootDepth = _parseNullable(_rootPlateDepthController);
    
    if (dbh != null && rootRadius != null && rootRadius > 0) {
      // Expected root plate radius ≈ 3-4x DBH for most trees
      final expectedRadius = (dbh / 100) * 3.5; // DBH in cm, radius in m
      final radiusRatio = rootRadius / expectedRadius;
      if (radiusRatio < 0.7) {
        factor *= 0.75; // Undersized root plate
      } else if (radiusRatio < 0.9) {
        factor *= 0.90;
      }
    }
    
    if (rootDepth != null && rootDepth > 0) {
      // Shallow root plates are less stable
      if (rootDepth < 0.3) {
        factor *= 0.70; // Very shallow
      } else if (rootDepth < 0.5) {
        factor *= 0.85;
      }
    }
    
    return factor.clamp(0.2, 1.1);
  }

  /// Returns overall stability assessment combining stem and root factors
  String _getRootPlateRiskRating() {
    final factor = _computeRootPlateStabilityFactor();
    if (factor >= 0.9) return 'Low Risk';
    if (factor >= 0.7) return 'Moderate Risk';
    if (factor >= 0.5) return 'High Risk';
    return 'Critical Risk';
  }

  Map<String, dynamic> _buildExportPayload() {
    final dbh = _parseNullable(_dbhController);
    final height = _parseNullable(_heightController);
    final crown = _parseNullable(_crownDiameterController);
    final wind = _parseNullable(_designWindController);
    final cavity = _parseNullable(_cavityController);

    final treeLabelRaw = _treeLabelController.text.trim();
    final treeLabel = treeLabelRaw.isEmpty ? 'Tree 1' : treeLabelRaw;
    final siteLocation = _siteLocationController.text.trim();
    final defectSummary = _buildDefectSummary();

    final defectFactor = _computeDefectStrengthFactor();

    final result = _mainResult;

    return <String, dynamic>{
      'schema_version': 1,
      'tree': {
        'label': treeLabel,
        'species': _selectedSpecies.displayName,
        'site_location': siteLocation,
      },
      'inputs': {
        'dbh_cm': dbh,
        'height_m': height,
        'crown_diameter_m': crown,
        'cavity_inner_diameter_cm': cavity,
        'design_wind_speed_ms': wind,
        'site_factor': _siteFactor,
      },
      'defects': {
        'bracket_fungi': _defectBracketFungi,
        'cavity_decay': _defectCavityDecay,
        'cracks': _defectCracks,
        'basal_decay': _defectBasalDecay,
        'union': _defectUnion,
        'other': defectSummary,
        'strength_factor_k_defect': defectFactor,
      },
      'results': result == null
          ? null
          : {
              'safety_factor': result.safetyFactor,
              'bending_stress_mpa': result.bendingStressMPa,
              'wind_pressure_pa': result.qPa,
              'wind_force_n': result.windForceN,
              'bending_moment_nm': result.bendingMomentNm,
              'wind_to_failure_ms': _windToFailureMs,
            },
      'decay': {
        'current_residual_percent': _decayCurrentResidualPercent,
        'critical_residual_percent': _decayCriticalResidualPercent,
        'critical_wall_thickness_cm': _decayCriticalWallThicknessCm,
      },
      'graphs': {
        'sf_vs_wind': {
          'wind_ms': _sfWindSpeeds,
          'sf': _sfWindSafetyFactors,
        },
        'sf_vs_residual_wall': {
          'residual_wall_percent': _residualWallPercents,
          'sf': _residualWallSafetyFactors,
        },
        'sf_vs_crown_reduction': {
          'reduction_percent': _reductionPercents,
          'sf': _reductionSafetyFactors,
        },
      },
      'text': {
        'short_summary': _shortSummary.trim(),
        'technical_appendix': _technicalAppendix.trim(),
        'base_calculation': _baseCalculationText.trim(),
      },
    };
  }

  /// Computes the current residual wall fraction (0–1) at the
  /// assessment height based on DBH and an internal cavity
  /// diameter. 1.0 means solid (no cavity modelled); lower values
  /// indicate greater section loss.
  double _computeResidualWallFraction(double dbhCm, double? cavityInnerCm) {
    if (dbhCm <= 0) return 1.0;
    if (cavityInnerCm == null || cavityInnerCm <= 0) {
      return 1.0;
    }
    double cav = cavityInnerCm;
    if (cav >= dbhCm) {
      cav = dbhCm * 0.99;
    }
    final frac = (dbhCm - cav) / dbhCm;
    if (frac < 0.0) return 0.0;
    if (frac > 1.0) return 1.0;
    return frac;
  }

  Future<void> _onExportJson() async {
    if (_mainResult == null) return;

    final payload = _buildExportPayload();
    final encoder = const JsonEncoder.withIndent('  ');
    final jsonText = encoder.convert(payload);

    await Clipboard.setData(ClipboardData(text: jsonText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Report JSON copied to clipboard. Paste into a .json file to build a Word report.',
        ),
      ),
    );
  }

  Future<void> _onExportWord() async {
    if (_mainResult == null) return;
    
    final result = _mainResult!;
    final treeLabel = _treeLabelController.text.trim().isEmpty ? 'Tree 1' : _treeLabelController.text.trim();
    final siteLocation = _siteLocationController.text.trim();
    final date = DateTime.now();
    final dateStr = '${date.day}/${date.month}/${date.year}';
    
    final dbh = _parseNullable(_dbhController) ?? 0;
    final height = _parseNullable(_heightController) ?? 0;
    final crown = _parseNullable(_crownDiameterController) ?? 0;
    final wind = _parseNullable(_designWindController) ?? 0;
    final cavity = _parseNullable(_cavityController);
    
    final ratingLabel = As4970Language.safetyFactorRatingLabel(result.safetyFactor);
    final ratingDetail = As4970Language.interpretSafetyFactorRange(result.safetyFactor);
    final rootFactor = _computeRootPlateStabilityFactor();
    final rootRating = _getRootPlateRiskRating();
    
    final sfColor = result.safetyFactor >= 1.5 ? '#22c55e' : result.safetyFactor >= 1.0 ? '#eab308' : '#ef4444';
    
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>AusTreeCalc Report - $treeLabel</title>
  <style>
    body { font-family: Calibri, Arial, sans-serif; margin: 40px; color: #333; }
    h1 { color: #166534; border-bottom: 2px solid #166534; padding-bottom: 10px; }
    h2 { color: #1e40af; margin-top: 30px; }
    h3 { color: #6b7280; }
    .header-info { background: #f3f4f6; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
    .safety-factor { font-size: 48px; font-weight: bold; color: $sfColor; }
    .result-box { background: #f0fdf4; border: 2px solid #22c55e; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .warning-box { background: #fef3c7; border: 2px solid #f59e0b; padding: 15px; border-radius: 8px; margin: 20px 0; }
    table { border-collapse: collapse; width: 100%; margin: 15px 0; }
    th, td { border: 1px solid #d1d5db; padding: 10px; text-align: left; }
    th { background: #f3f4f6; }
    .disclaimer { background: #fef2f2; border: 1px solid #fca5a5; padding: 15px; border-radius: 8px; margin-top: 30px; font-size: 12px; }
    .section { margin-bottom: 30px; }
  </style>
</head>
<body>
  <h1>🌳 AusTreeCalc - Tree Stability Assessment Report</h1>
  
  <div class="header-info">
    <strong>Tree ID:</strong> $treeLabel<br>
    ${siteLocation.isNotEmpty ? '<strong>Location:</strong> $siteLocation<br>' : ''}
    <strong>Assessment Date:</strong> $dateStr<br>
    <strong>Species:</strong> ${_selectedSpecies.displayName}
  </div>

  <h2>📊 Summary Result</h2>
  <div class="result-box">
    <span class="safety-factor">${result.safetyFactor.toStringAsFixed(2)}</span>
    <span style="font-size: 24px; margin-left: 20px;">$ratingLabel</span>
    <p style="margin-top: 15px; color: #6b7280;">$ratingDetail</p>
  </div>

  <h2>📏 Tree Dimensions</h2>
  <table>
    <tr><th>Parameter</th><th>Value</th></tr>
    <tr><td>DBH (Diameter at Breast Height)</td><td>${dbh.toStringAsFixed(1)} cm</td></tr>
    <tr><td>Total Height</td><td>${height.toStringAsFixed(1)} m</td></tr>
    <tr><td>Crown Diameter</td><td>${crown.toStringAsFixed(1)} m</td></tr>
    ${cavity != null ? '<tr><td>Cavity Inner Diameter</td><td>${cavity.toStringAsFixed(1)} cm</td></tr>' : ''}
  </table>

  <h2>💨 Wind Loading Analysis</h2>
  <table>
    <tr><th>Parameter</th><th>Value</th></tr>
    <tr><td>Design Wind Speed</td><td>${wind.toStringAsFixed(1)} m/s</td></tr>
    <tr><td>Wind Pressure (q)</td><td>${(result.qPa / 1000).toStringAsFixed(2)} kPa</td></tr>
    <tr><td>Wind Force on Crown (F)</td><td>${(result.windForceN / 1000).toStringAsFixed(2)} kN</td></tr>
    <tr><td>Bending Moment at Base (M)</td><td>${(result.bendingMomentNm / 1000).toStringAsFixed(2)} kN·m</td></tr>
    <tr><td>Bending Stress (σ)</td><td>${result.bendingStressMPa.toStringAsFixed(2)} MPa</td></tr>
  </table>

  ${_showRootPlateAnalysis ? '''
  <h2>🌱 Root Plate Analysis</h2>
  <table>
    <tr><th>Parameter</th><th>Value</th></tr>
    <tr><td>Soil Type</td><td>${_soilType.replaceAll('_', ' ')}</td></tr>
    <tr><td>Soil Moisture</td><td>$_soilMoisture</td></tr>
    <tr><td>Lean Angle</td><td>${_leanAngleDegrees.toStringAsFixed(0)}°</td></tr>
    <tr><td>Root Plate Stability Factor</td><td>${rootFactor.toStringAsFixed(2)}</td></tr>
    <tr><td>Risk Rating</td><td>$rootRating</td></tr>
  </table>
  ''' : ''}

  <h2>📋 Technical Summary</h2>
  <div class="section">
    ${_shortSummary.trim().replaceAll('\n', '<br>')}
  </div>

  ${_windToFailureMs != null ? '''
  <div class="warning-box">
    <strong>⚠️ Wind-to-Failure Estimate:</strong> ${_windToFailureMs!.toStringAsFixed(1)} m/s<br>
    <small>This is the estimated wind speed at which the safety factor approaches 1.0</small>
  </div>
  ''' : ''}

  <h2>📝 Technical Appendix</h2>
  <div class="section" style="font-family: monospace; font-size: 11px; white-space: pre-wrap; background: #f9fafb; padding: 15px; border-radius: 8px;">
${_technicalAppendix.trim()}
  </div>

  <div class="disclaimer">
    <strong>⚠️ Disclaimer:</strong> This assessment is based on a simplified static biomechanical model. 
    Results are estimates only and should be combined with professional arborist judgement. 
    This tool does not replace qualified tree risk assessment. 
    The calculations are based on AS 4970-2009 principles but are not a certified engineering analysis.
  </div>

  <p style="color: #9ca3af; font-size: 11px; margin-top: 30px;">
    Generated by AusTreeCalc | ${DateTime.now().toIso8601String()}
  </p>
</body>
</html>
''';

    // For Flutter web, we'll copy to clipboard and show instructions
    await Clipboard.setData(ClipboardData(text: html));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('HTML report copied! Paste into a .html file and open with Word.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _treeLabelController.dispose();
    _siteLocationController.dispose();
    _dbhController.dispose();
    _heightController.dispose();
    _crownDiameterController.dispose();
    _cavityController.dispose();
    _designWindController.dispose();
    _defectOtherController.dispose();
    super.dispose();
  }

  double? _parseNullable(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  void _applyWindPreset(WindPreset preset) {
    setState(() {
      _selectedWindPreset = preset;
      _designWindController.text =
          preset.designWindSpeedMs.toStringAsFixed(1);
      _revalidate();
    });
  }

  void _revalidate() {
    final dbh = _parseNullable(_dbhController);
    final height = _parseNullable(_heightController);
    final crown = _parseNullable(_crownDiameterController);
    final wind = _parseNullable(_designWindController);
    final cavity = _parseNullable(_cavityController);

    _issues = AusTreeCalcService.validateInputs(
      dbhCm: dbh,
      heightM: height,
      crownDiameterM: crown,
      designWindSpeedMs: wind,
      cavityInnerDiameterCm: cavity,
    );
    setState(() {});
  }

  bool get _hasErrors => _issues.any((i) => i.isError);

  void _onCalculate() {
    final dbh = _parseNullable(_dbhController);
    final height = _parseNullable(_heightController);
    final crown = _parseNullable(_crownDiameterController);
    final wind = _parseNullable(_designWindController);
    final cavity = _parseNullable(_cavityController);

    if (dbh == null ||
        height == null ||
        crown == null ||
        wind == null ||
        dbh <= 0 ||
        height <= 0 ||
        crown <= 0 ||
        wind <= 0) {
      return;
    }

    final defectFactor = _computeDefectStrengthFactor();

    final currentResidualFrac = _computeResidualWallFraction(dbh, cavity);
    final currentResidualPercent = currentResidualFrac * 100.0;

    final result = AusTreeCalcService.calculateSingle(
      species: _selectedSpecies,
      dbhCm: dbh,
      heightM: height,
      crownDiameterM: crown,
      designWindSpeedMs: wind,
      cavityInnerDiameterCm: cavity,
      crownFullnessOverride: _crownFullnessOverride,
      siteFactor: _siteFactor,
      defectStrengthFactor: defectFactor,
    );

    final windToFailure = AusTreeCalcService.estimateWindToFailure(
      species: _selectedSpecies,
      dbhCm: dbh,
      heightM: height,
      crownDiameterM: crown,
      designWindSpeedMs: wind,
      cavityInnerDiameterCm: cavity,
      crownFullnessOverride: _crownFullnessOverride,
      siteFactor: _siteFactor,
    );

    PruningScenarioResult? pruningResult;
    if (_simulatePruning) {
      pruningResult = AusTreeCalcService.calculatePruningScenario(
        species: _selectedSpecies,
        dbhCm: dbh,
        heightM: height,
        crownDiameterM: crown,
        designWindSpeedMs: wind,
        cavityInnerDiameterCm: cavity,
        crownFullnessOverride: _crownFullnessOverride,
        siteFactor: _siteFactor,
        defectStrengthFactor: defectFactor,
        crownDiameterReductionPercent: _crownDiameterReductionPercent,
        fullnessReductionPercent: _fullnessReductionPercent,
      );
    }

    final postWarnings = AusTreeCalcService.postCalculationWarnings(result);

    // Build SF vs wind-speed curve using the same engine (decision-support only).
    final sfXs = <double>[];
    final sfYs = <double>[];
    double minV = wind * 0.5;
    if (minV < 5.0) {
      minV = 5.0;
    }
    double maxV = wind * 1.8;
    if (windToFailure != null && windToFailure.isFinite && windToFailure > 0) {
      final extended = windToFailure * 1.1;
      if (extended > maxV) {
        maxV = extended;
      }
    }
    if (maxV <= minV) {
      maxV = minV + 5.0;
    }

    const int steps = 12;
    for (var i = 0; i < steps; i++) {
      final v = minV + (maxV - minV) * i / (steps - 1);
      final resV = AusTreeCalcService.calculateSingle(
        species: _selectedSpecies,
        dbhCm: dbh,
        heightM: height,
        crownDiameterM: crown,
        designWindSpeedMs: v,
        cavityInnerDiameterCm: cavity,
        crownFullnessOverride: _crownFullnessOverride,
        siteFactor: _siteFactor,
        defectStrengthFactor: defectFactor,
      );
      sfXs.add(v);
      sfYs.add(resV.safetyFactor);
    }

    // Build SF vs crown reduction curve (using current thinning setting).
    final redXs = <double>[];
    final redYs = <double>[];
    if (_simulatePruning) {
      final maxRedNum = _crownDiameterReductionPercent <= 0
          ? 10.0
          : _crownDiameterReductionPercent.clamp(5.0, 40.0);
      final maxRed = maxRedNum is double ? maxRedNum : maxRedNum.toDouble();
      const int redSteps = 9;
      for (var i = 0; i < redSteps; i++) {
        final r = maxRed * i / (redSteps - 1);
        final scenario = AusTreeCalcService.calculatePruningScenario(
          species: _selectedSpecies,
          dbhCm: dbh,
          heightM: height,
          crownDiameterM: crown,
          designWindSpeedMs: wind,
          cavityInnerDiameterCm: cavity,
          crownFullnessOverride: _crownFullnessOverride,
          siteFactor: _siteFactor,
          defectStrengthFactor: defectFactor,
          crownDiameterReductionPercent: r,
          fullnessReductionPercent: _fullnessReductionPercent,
        );
        redXs.add(r);
        redYs.add(scenario.after.safetyFactor);
      }
    }

    // Build SF vs residual wall curve (decay progression) at current wind.
    final rwXs = <double>[];
    final rwYs = <double>[];
    const int rwSteps = 9;
    const double rwMin = 20.0;
    const double rwMax = 100.0;
    for (var i = 0; i < rwSteps; i++) {
      final rw = rwMin + (rwMax - rwMin) * i / (rwSteps - 1);
      final frac = rw / 100.0;
      final cavSimCm = dbh * (1.0 - frac);
      final sim = AusTreeCalcService.calculateSingle(
        species: _selectedSpecies,
        dbhCm: dbh,
        heightM: height,
        crownDiameterM: crown,
        designWindSpeedMs: wind,
        cavityInnerDiameterCm: cavSimCm > 0 ? cavSimCm : null,
        crownFullnessOverride: _crownFullnessOverride,
        siteFactor: _siteFactor,
        defectStrengthFactor: defectFactor,
      );
      rwXs.add(rw);
      rwYs.add(sim.safetyFactor);
    }

    double? criticalRw;
    if (rwXs.length >= 2) {
      for (var i = 0; i < rwXs.length - 1; i++) {
        final y1 = rwYs[i];
        final y2 = rwYs[i + 1];
        if (!y1.isFinite || !y2.isFinite) continue;
        if ((y1 >= 1.0 && y2 <= 1.0) || (y1 <= 1.0 && y2 >= 1.0)) {
          final x1 = rwXs[i];
          final x2 = rwXs[i + 1];
          final t = (1.0 - y1) / (y2 - y1);
          final x = x1 + (x2 - x1) * t;
          criticalRw = x.clamp(rwMin, rwMax);
          break;
        }
      }
    }

    double? criticalWallCm;
    if (criticalRw != null) {
      criticalWallCm = dbh * (criticalRw / 100.0) / 2.0;
    }

    final sliderDefault = currentResidualPercent.isFinite
        ? currentResidualPercent.clamp(rwMin, rwMax)
        : 60.0;

    // Build decay tolerance vs wind speed curve.
    // For each wind speed, find the critical residual wall % where SF ≈ 1.
    final dtWinds = <double>[];
    final dtCriticalWalls = <double>[];
    double dtMinV = 15.0;
    double dtMaxV = wind * 1.5;
    if (dtMaxV < 50.0) dtMaxV = 50.0;
    if (dtMaxV > 80.0) dtMaxV = 80.0;
    const int dtSteps = 10;

    for (var i = 0; i < dtSteps; i++) {
      final v = dtMinV + (dtMaxV - dtMinV) * i / (dtSteps - 1);
      
      // Binary search for critical residual wall at this wind speed
      double lowRw = 10.0;
      double highRw = 100.0;
      double? criticalRwAtV;
      
      for (var iter = 0; iter < 20; iter++) {
        final midRw = (lowRw + highRw) / 2.0;
        final frac = midRw / 100.0;
        final cavSimCm = dbh * (1.0 - frac);
        final sim = AusTreeCalcService.calculateSingle(
          species: _selectedSpecies,
          dbhCm: dbh,
          heightM: height,
          crownDiameterM: crown,
          designWindSpeedMs: v,
          cavityInnerDiameterCm: cavSimCm > 0 ? cavSimCm : null,
          crownFullnessOverride: _crownFullnessOverride,
          siteFactor: _siteFactor,
          defectStrengthFactor: defectFactor,
        );
        
        if (!sim.safetyFactor.isFinite) {
          lowRw = midRw;
          continue;
        }
        
        if ((sim.safetyFactor - 1.0).abs() < 0.02) {
          criticalRwAtV = midRw;
          break;
        }
        
        if (sim.safetyFactor > 1.0) {
          // SF > 1 means we have enough wall, try lower
          highRw = midRw;
        } else {
          // SF < 1 means not enough wall, need more
          lowRw = midRw;
        }
        
        criticalRwAtV = midRw;
      }
      
      if (criticalRwAtV != null && criticalRwAtV > 10 && criticalRwAtV < 100) {
        dtWinds.add(v);
        dtCriticalWalls.add(criticalRwAtV);
      }
    }

    // Build wind scenario comparison (SF at different regional wind speeds).
    final windScenarios = <String, double>{};
    final scenarioWinds = <String, double>{
      'Region A (32)': 32.0,
      'Region B (40)': 40.0,
      'Region C (50)': 50.0,
      'Region D (60)': 60.0,
      'Cyclone (69)': 69.0,
    };
    for (final entry in scenarioWinds.entries) {
      final scenarioResult = AusTreeCalcService.calculateSingle(
        species: _selectedSpecies,
        dbhCm: dbh,
        heightM: height,
        crownDiameterM: crown,
        designWindSpeedMs: entry.value,
        cavityInnerDiameterCm: cavity,
        crownFullnessOverride: _crownFullnessOverride,
        siteFactor: _siteFactor,
        defectStrengthFactor: defectFactor,
      );
      windScenarios[entry.key] = scenarioResult.safetyFactor;
    }

    setState(() {
      _mainResult = result;
      _pruningResult = pruningResult;
      _windToFailureMs = windToFailure;
      _postCalcWarnings = postWarnings;
      _sfWindSpeeds = sfXs;
      _sfWindSafetyFactors = sfYs;
      _reductionPercents = redXs;
      _reductionSafetyFactors = redYs;
      _residualWallPercents = rwXs;
      _residualWallSafetyFactors = rwYs;
      _decayToleranceWindSpeeds = dtWinds;
      _decayToleranceCriticalWalls = dtCriticalWalls;
      _windScenarioSafetyFactors = windScenarios;
      _decayCurrentResidualPercent =
          currentResidualPercent.isFinite ? currentResidualPercent : null;
      _decayCriticalResidualPercent = criticalRw;
      _decayCriticalWallThicknessCm = criticalWallCm;
      _decaySimResidualWallPercent = sliderDefault;
      _shortSummary = '';
      _technicalAppendix = '';
      _baseCalculationText = CalculationBreakdownBuilder.buildBreakdown(
        species: _selectedSpecies,
        dbhCm: dbh,
        heightM: height,
        crownDiameterM: crown,
        cavityInnerDiameterCm: cavity,
        designWindSpeedMs: wind,
        crownFullnessOverride: _crownFullnessOverride,
        siteFactor: _siteFactor,
        result: result,
        defectStrengthFactor: defectFactor,
      );
    });
  }

  void _onGenerateReport() {
    if (_mainResult == null) return;

    final dbh = _parseNullable(_dbhController)!;
    final height = _parseNullable(_heightController)!;
    final crown = _parseNullable(_crownDiameterController)!;
    final wind = _parseNullable(_designWindController)!;
    final cavity = _parseNullable(_cavityController);

    final rawLabel = _treeLabelController.text.trim();
    final treeLabel = rawLabel.isEmpty ? 'Tree 1' : rawLabel;
    final speciesLabel = _selectedSpecies.displayName;
    const governingSectionLabel = 'main stem at assessment height';

    final siteLocation = _siteLocationController.text.trim();
    final defectSummary = _buildDefectSummary();

    final shortSummary = ShortSummaryGenerator.buildShortSummary(
      treeLabel: treeLabel,
      speciesLabel: speciesLabel,
      governingSectionLabel: governingSectionLabel,
      designWindSpeedMs: wind,
      governingSectionResult: _mainResult!,
      windToFailureMs: _windToFailureMs,
      siteLocation: siteLocation.isEmpty ? null : siteLocation,
      defectSummary: defectSummary.isEmpty ? null : defectSummary,
    );

    final techAppendix = TechnicalAppendixBuilder.buildTechnicalAppendix(
      treeLabel: treeLabel,
      speciesLabel: speciesLabel,
      governingSectionLabel: governingSectionLabel,
      dbhCm: dbh,
      heightM: height,
      crownDiameterM: crown,
      cavityInnerDiameterCm: cavity,
      designWindSpeedMs: wind,
      governingSectionResult: _mainResult!,
      windToFailureMs: _windToFailureMs,
      siteLocation: siteLocation.isEmpty ? null : siteLocation,
      defectSummary: defectSummary.isEmpty ? null : defectSummary,
      pruningScenario: _pruningResult,
      baseCalculationText:
          _baseCalculationText.trim().isEmpty ? null : _baseCalculationText,
    );

    setState(() {
      _shortSummary = shortSummary;
      _technicalAppendix = techAppendix;
    });
  }

  Future<void> _copyReportToClipboard() async {
    final fullText = '${_shortSummary.trim()}\n\n${_technicalAppendix.trim()}';
    if (fullText.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: fullText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report text copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speciesList = SpeciesPresets.list;
    final windList = WindPresets.list;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final horizontalPadding = isMobile ? 12.0 : isTablet ? 24.0 : 48.0;
    final maxContentWidth = 800.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMobile ? 'AusTreeCalc' : 'AusTreeCalc – Advanced Tree Stability Modeller',
          style: TextStyle(fontSize: isMobile ? 18 : 22),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxContentWidth,
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTreeInputsCard(theme, speciesList),
                      const SizedBox(height: 12),
                      _buildWindInputsCard(theme, windList),
                      const SizedBox(height: 12),
                      _buildValidationCard(theme),
                      const SizedBox(height: 12),
                      _buildResultsCard(theme),
                      const SizedBox(height: 12),
                      _buildDecayCard(theme),
                      const SizedBox(height: 12),
                      _buildRootPlateCard(theme),
                      const SizedBox(height: 12),
                      _buildLiveSimulatorCard(theme),
                      const SizedBox(height: 12),
                      _buildPruningCard(theme),
                      const SizedBox(height: 12),
                      _buildReportCard(theme),
                      const SizedBox(height: 12),
                      _buildMethodologyCard(theme),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds a responsive row that stacks to column on mobile
  Widget _buildResponsiveRow(BuildContext context, List<Widget> children) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: child,
        )).toList(),
      );
    }
    
    return Row(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index > 0 ? 12 : 0),
            child: child,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTreeInputsCard(
      ThemeData theme, List<SpeciesPreset> speciesList) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernCardHeader('Tree Inputs', Icons.park_rounded, const Color(0xFF4ade80), subtitle: 'Species & dimensions'),
            const SizedBox(height: 20),
            TextField(
              controller: _treeLabelController,
              decoration: const InputDecoration(
                labelText: 'Tree label / ID',
                hintText: 'e.g. Tree 1, Street gum near driveway',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _siteLocationController,
              decoration: const InputDecoration(
                labelText: 'Site / location',
                hintText: 'e.g. 123 Example St, front setback',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SpeciesPreset>(
              value: _selectedSpecies,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Species preset',
              ),
              items: speciesList
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (sp) {
                if (sp == null) return;
                setState(() {
                  _selectedSpecies = sp;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildResponsiveRow(context, [
              TextField(
                controller: _dbhController,
                decoration: const InputDecoration(
                  labelText: 'DBH (cm)',
                  hintText: 'e.g. 50',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _revalidate(),
              ),
              TextField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height (m)',
                  hintText: 'e.g. 18',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _revalidate(),
              ),
            ]),
            const SizedBox(height: 12),
            _buildResponsiveRow(context, [
              TextField(
                controller: _crownDiameterController,
                decoration: const InputDecoration(
                  labelText: 'Crown diameter (m)',
                  hintText: 'e.g. 10',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _revalidate(),
              ),
              TextField(
                controller: _cavityController,
                decoration: const InputDecoration(
                  labelText: 'Cavity inner diameter (cm)',
                  hintText: 'optional',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _revalidate(),
              ),
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  value: _showAdvanced,
                  onChanged: (val) {
                    setState(() {
                      _showAdvanced = val;
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text('Show advanced options'),
              ],
            ),
            if (_showAdvanced) ...[
              const SizedBox(height: 8),
              Text(
                'Optional crown fullness override (0–1)',
                style: theme.textTheme.bodyMedium,
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: (_crownFullnessOverride ??
                              _selectedSpecies.defaultFullness)
                          .clamp(0.1, 1.0),
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label:
                          '${((_crownFullnessOverride ?? _selectedSpecies.defaultFullness) * 100).toStringAsFixed(0)}%',
                      onChanged: (v) {
                        setState(() {
                          _crownFullnessOverride = v;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Reset to species default',
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        _crownFullnessOverride = null;
                      });
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Observed structural defects / decay indicators',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bracket fungi on stem or base'),
              value: _defectBracketFungi,
              onChanged: (v) {
                setState(() {
                  _defectBracketFungi = v ?? false;
                });
              },
            ),
            if (_defectBracketFungi) ...[
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 8),
                child: Row(
                  children: [
                    const Text('Fruiting bodies observed: '),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _fruitingBodyCount,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('None visible')),
                        DropdownMenuItem(value: 1, child: Text('1')),
                        DropdownMenuItem(value: 2, child: Text('2-3')),
                        DropdownMenuItem(value: 4, child: Text('4-5')),
                        DropdownMenuItem(value: 6, child: Text('6+')),
                      ],
                      onChanged: (v) => setState(() => _fruitingBodyCount = v ?? 0),
                    ),
                  ],
                ),
              ),
            ],
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cavity with visible decay'),
              value: _defectCavityDecay,
              onChanged: (v) {
                setState(() {
                  _defectCavityDecay = v ?? false;
                });
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Longitudinal cracks / shear planes'),
              value: _defectCracks,
              onChanged: (v) {
                setState(() {
                  _defectCracks = v ?? false;
                });
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Basal/root-plate decay symptoms'),
              value: _defectBasalDecay,
              onChanged: (v) {
                setState(() {
                  _defectBasalDecay = v ?? false;
                });
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Included bark / compromised unions'),
              value: _defectUnion,
              onChanged: (v) {
                setState(() {
                  _defectUnion = v ?? false;
                });
              },
            ),
            const SizedBox(height: 8),
            // Toggle for advanced decay options
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show advanced decay parameters'),
              subtitle: const Text('Decay type, location, severity, resonance test'),
              value: _showAdvancedDecay,
              onChanged: (v) => setState(() => _showAdvancedDecay = v),
            ),
            if (_showAdvancedDecay) ...[
              const Divider(),
              Text('Decay characterisation', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _decayType,
                      decoration: const InputDecoration(
                        labelText: 'Decay type',
                        helperText: 'Type of rot if identifiable',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'unknown', child: Text('Unknown / not identified')),
                        DropdownMenuItem(value: 'white_rot', child: Text('White rot (e.g. Ganoderma, Trametes)')),
                        DropdownMenuItem(value: 'brown_rot', child: Text('Brown rot (e.g. Laetiporus)')),
                        DropdownMenuItem(value: 'soft_rot', child: Text('Soft rot (surface decay)')),
                      ],
                      onChanged: (v) => setState(() => _decayType = v ?? 'unknown'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _decayLocation,
                      decoration: const InputDecoration(
                        labelText: 'Primary decay location',
                        helperText: 'Where is the decay most significant?',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'root_plate', child: Text('Root plate / buttress roots')),
                        DropdownMenuItem(value: 'stem_base', child: Text('Stem base (0-1m)')),
                        DropdownMenuItem(value: 'mid_stem', child: Text('Mid-stem (1-5m)')),
                        DropdownMenuItem(value: 'upper_stem', child: Text('Upper stem / scaffold')),
                      ],
                      onChanged: (v) => setState(() => _decayLocation = v ?? 'stem_base'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _decaySeverity,
                      decoration: const InputDecoration(
                        labelText: 'Decay severity',
                        helperText: 'Estimated extent of cross-section affected',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'minor', child: Text('Minor (<10% cross-section)')),
                        DropdownMenuItem(value: 'moderate', child: Text('Moderate (10-30%)')),
                        DropdownMenuItem(value: 'severe', child: Text('Severe (30-50%)')),
                        DropdownMenuItem(value: 'extensive', child: Text('Extensive (>50%)')),
                      ],
                      onChanged: (v) => setState(() => _decaySeverity = v ?? 'moderate'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Estimated decay extent: ${_estimatedDecayExtentPercent.toStringAsFixed(0)}%'),
              Slider(
                value: _estimatedDecayExtentPercent,
                min: 0,
                max: 80,
                divisions: 16,
                label: '${_estimatedDecayExtentPercent.toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _estimatedDecayExtentPercent = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _resonanceTestResult,
                      decoration: const InputDecoration(
                        labelText: 'Resonance / sounding test result',
                        helperText: 'Mallet test on stem',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'not_done', child: Text('Not performed')),
                        DropdownMenuItem(value: 'solid', child: Text('Solid (clear sound)')),
                        DropdownMenuItem(value: 'drum', child: Text('Drum-like (some hollowness)')),
                        DropdownMenuItem(value: 'hollow', child: Text('Hollow (significant void)')),
                      ],
                      onChanged: (v) => setState(() => _resonanceTestResult = v ?? 'not_done'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _decayColumnHeightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Estimated decay column height (m)',
                  helperText: 'Vertical extent of internal decay if known',
                  hintText: 'e.g. 2.5',
                ),
              ),
              const Divider(),
              // Display calculated k_defect factor
              Builder(
                builder: (context) {
                  final kDefect = _computeDefectStrengthFactor();
                  final MaterialColor factorColor;
                  final String factorDesc;
                  if (kDefect >= 0.8) {
                    factorColor = Colors.green;
                    factorDesc = 'Minor reduction';
                  } else if (kDefect >= 0.6) {
                    factorColor = Colors.orange;
                    factorDesc = 'Moderate reduction';
                  } else if (kDefect >= 0.4) {
                    factorColor = Colors.deepOrange;
                    factorDesc = 'Significant reduction';
                  } else {
                    factorColor = Colors.red;
                    factorDesc = 'Severe reduction';
                  }
                  return Card(
                    color: factorColor.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Defect strength factor (k_defect): ${kDefect.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: factorColor.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            factorDesc,
                            style: TextStyle(color: factorColor.shade700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Effective strength = ${(kDefect * 100).toStringAsFixed(0)}% of species baseline',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _defectOtherController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Other defect / decay observations (optional)',
                hintText: 'e.g. old pruning wounds with decay, girdling roots',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindInputsCard(ThemeData theme, List<WindPreset> windList) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernCardHeader('Wind Inputs', Icons.air_rounded, const Color(0xFF22d3ee), subtitle: 'Region & exposure'),
            const SizedBox(height: 20),
            DropdownButtonFormField<WindPreset>(
              value: _selectedWindPreset,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Region / Exposure preset',
              ),
              items: windList
                  .map(
                    (w) => DropdownMenuItem(
                      value: w,
                      child: Text(
                          '${w.displayName} (${w.designWindSpeedMs.toStringAsFixed(0)} m/s)'),
                    ),
                  )
                  .toList(),
              onChanged: (wp) {
                if (wp == null) return;
                _applyWindPreset(wp);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _designWindController,
              decoration: const InputDecoration(
                labelText: 'Design wind speed (m/s)',
                helperText:
                    'Can override preset; approximate gust at tree height.',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _revalidate(),
            ),
            const SizedBox(height: 16),
            Text(
              'Site factor (exposure / topography)',
              style: theme.textTheme.bodyMedium,
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _siteFactor,
                    min: 0.5,
                    max: 1.5,
                    divisions: 10,
                    label: _siteFactor.toStringAsFixed(2),
                    onChanged: (v) {
                      setState(() {
                        _siteFactor = v;
                      });
                    },
                  ),
                ),
                Text(_siteFactor.toStringAsFixed(2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationCard(ThemeData theme) {
    final allIssues = [
      ..._issues,
      ..._postCalcWarnings,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernCardHeader(
              'Validation',
              allIssues.isEmpty ? Icons.check_circle_rounded : Icons.warning_rounded,
              allIssues.isEmpty ? const Color(0xFF4ade80) : const Color(0xFFfbbf24),
              subtitle: allIssues.isEmpty ? 'All inputs valid' : '${allIssues.length} issue(s) detected',
            ),
            const SizedBox(height: 16),
            if (allIssues.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ade80).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4ade80).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF4ade80), size: 20),
                    SizedBox(width: 10),
                    Text('No issues detected', style: TextStyle(color: Color(0xFF4ade80))),
                  ],
                ),
              )
            else
              Column(
                children: allIssues
                    .map(
                      (i) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (i.isError ? const Color(0xFFef4444) : const Color(0xFFfbbf24)).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: (i.isError ? const Color(0xFFef4444) : const Color(0xFFfbbf24)).withOpacity(0.3)),
                        ),
                        child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            i.isError
                                ? Icons.error_rounded
                                : Icons.warning_rounded,
                            color: i.isError ? const Color(0xFFef4444) : const Color(0xFFfbbf24),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              i.message,
                              style: TextStyle(
                                color: i.isError
                                    ? const Color(0xFFfca5a5)
                                    : const Color(0xFFfcd34d),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _hasErrors ? null : _onCalculate,
                icon: const Icon(Icons.calculate),
                label: const Text('Calculate structural margin'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(ThemeData theme) {
    final result = _mainResult;
    if (result == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildModernCardHeader('Results', Icons.analytics_rounded, const Color(0xFF6366f1), subtitle: 'Pending calculation'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Enter inputs and tap Calculate', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final qKPa = result.qPa / 1000.0;
    final fKN = result.windForceN / 1000.0;
    final mKNm = result.bendingMomentNm / 1000.0;

    final ratingLabel =
        As4970Language.safetyFactorRatingLabel(result.safetyFactor);
    final ratingDetail =
        As4970Language.interpretSafetyFactorRange(result.safetyFactor);
    
    final sfColor = result.safetyFactor >= 1.5 ? const Color(0xFF4ade80) 
        : result.safetyFactor >= 1.0 ? const Color(0xFFfbbf24) 
        : const Color(0xFFef4444);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernCardHeader('Results', Icons.analytics_rounded, const Color(0xFF6366f1), subtitle: 'Structural margin analysis'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [sfColor.withOpacity(0.15), sfColor.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sfColor.withOpacity(0.3)),
              ),
              child: Row(
              children: [
                Text(
                  result.safetyFactor.isFinite
                      ? result.safetyFactor.toStringAsFixed(2)
                      : '∞',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: sfColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Safety Factor', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(ratingLabel, style: TextStyle(color: sfColor, fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(ratingDetail, style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5)),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: Text('Technical details', style: TextStyle(color: Colors.white.withOpacity(0.9))),
              iconColor: Colors.white54,
              collapsedIconColor: Colors.white54,
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                _detailRow('Wind pressure q', '${qKPa.toStringAsFixed(2)} kPa'),
                _detailRow(
                    'Wind force on crown', '${fKN.toStringAsFixed(2)} kN'),
                _detailRow('Bending moment at base',
                    '${mKNm.toStringAsFixed(2)} kNm'),
                _detailRow('Bending stress',
                    '${result.bendingStressMPa.toStringAsFixed(2)} MPa'),
                if (_windToFailureMs != null)
                  _detailRow('Estimated wind-to-failure (SF ≈ 1)',
                      '${_windToFailureMs!.toStringAsFixed(1)} m/s'),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text(
                  'Base calculation (formulas and numeric substitution)'),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                if (_baseCalculationText.trim().isEmpty)
                  Text(
                    'Base calculation breakdown will appear here after a successful calculation.',
                    style: theme.textTheme.bodySmall,
                  )
                else
                  SelectableText(
                    _baseCalculationText,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SafetyFactorVsWindGraph(
              windSpeeds: _sfWindSpeeds,
              safetyFactors: _sfWindSafetyFactors,
              designWindSpeed: _parseNullable(_designWindController),
              windToFailure: _windToFailureMs,
            ),
            const SizedBox(height: 16),
            CrossSectionDiagram(
              dbhCm: _parseNullable(_dbhController) ?? 50,
              cavityDiameterCm: _parseNullable(_cavityController),
              bendingStressMPa: result.bendingStressMPa,
              strengthMPa: _selectedSpecies.fbGreenMPa * _computeDefectStrengthFactor(),
            ),
            const SizedBox(height: 16),
            BendingMomentDiagram(
              heightM: _parseNullable(_heightController) ?? 15,
              maxMomentKNm: result.bendingMomentNm / 1000.0,
              crownDiameterM: _parseNullable(_crownDiameterController) ?? 8,
            ),
            const SizedBox(height: 16),
            WindScenarioComparison(
              scenarioSafetyFactors: _windScenarioSafetyFactors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecayCard(ThemeData theme) {
    final result = _mainResult;
    if (result == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildModernCardHeader('Decay Analysis', Icons.donut_large_rounded, const Color(0xFFf472b6), subtitle: 'Pending calculation'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Run a calculation first', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dbh = _parseNullable(_dbhController);
    final height = _parseNullable(_heightController);
    final crown = _parseNullable(_crownDiameterController);
    final wind = _parseNullable(_designWindController);
    double? sfAtSlider;
    if (dbh != null && height != null && crown != null && wind != null) {
      final defectFactor = _computeDefectStrengthFactor();
      final rw = _decaySimResidualWallPercent.clamp(20.0, 100.0);
      final frac = rw / 100.0;
      final cavSimCm = dbh * (1.0 - frac);
      final sim = AusTreeCalcService.calculateSingle(
        species: _selectedSpecies,
        dbhCm: dbh,
        heightM: height,
        crownDiameterM: crown,
        designWindSpeedMs: wind,
        cavityInnerDiameterCm: cavSimCm > 0 ? cavSimCm : null,
        crownFullnessOverride: _crownFullnessOverride,
        siteFactor: _siteFactor,
        defectStrengthFactor: defectFactor,
      );
      sfAtSlider = sim.safetyFactor;
    }

    final currentResidual = _decayCurrentResidualPercent;
    final criticalResidual = _decayCriticalResidualPercent;
    final criticalWall = _decayCriticalWallThicknessCm;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernCardHeader('Decay Analysis', Icons.donut_large_rounded, const Color(0xFFf472b6), subtitle: 'Residual wall simulation'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentResidual != null)
                    Text(
                      'Current: ${currentResidual.toStringAsFixed(0)}% residual wall',
                      style: const TextStyle(color: Color(0xFFf472b6), fontWeight: FontWeight.w600),
                    )
                  else
                    Text(
                      'No cavity - 100% solid section',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  if (criticalResidual != null && criticalWall != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Critical: ${criticalResidual.toStringAsFixed(0)}% (${criticalWall.toStringAsFixed(1)} cm)',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Simulated future residual wall (%)',
              style: theme.textTheme.bodyMedium,
            ),
            Slider(
              value: _decaySimResidualWallPercent.clamp(20.0, 100.0),
              min: 20.0,
              max: 100.0,
              divisions: 16,
              label: '${_decaySimResidualWallPercent.toStringAsFixed(0)}%',
              onChanged: (v) {
                setState(() {
                  _decaySimResidualWallPercent = v;
                });
              },
            ),
            if (sfAtSlider != null)
              Text(
                'At ${_decaySimResidualWallPercent.toStringAsFixed(0)}% '
                'residual wall, SF ≈ '
                '${sfAtSlider.isFinite ? sfAtSlider.toStringAsFixed(2) : 'very high'} '
                'at ${_designWindController.text.trim()} m/s.',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            ResidualWallGraph(
              residualWallPercents: _residualWallPercents,
              safetyFactors: _residualWallSafetyFactors,
              currentResidualPercent: _decayCurrentResidualPercent,
              criticalResidualPercent: _decayCriticalResidualPercent,
            ),
            const SizedBox(height: 16),
            DecayToleranceVsWindGraph(
              windSpeeds: _decayToleranceWindSpeeds,
              criticalResidualWallPercents: _decayToleranceCriticalWalls,
              designWindSpeed: _parseNullable(_designWindController),
              currentResidualPercent: _decayCurrentResidualPercent,
            ),
            const SizedBox(height: 16),
            _buildFailureThresholdTable(theme, dbh, height, crown),
          ],
        ),
      ),
    );
  }

  /// Builds a detailed table showing timber failure thresholds at different wind speeds.
  Widget _buildFailureThresholdTable(ThemeData theme, double? dbh, double? height, double? crown) {
    if (dbh == null || height == null || crown == null) {
      return const SizedBox.shrink();
    }
    if (_decayToleranceWindSpeeds.isEmpty) {
      return const SizedBox.shrink();
    }

    final defectFactor = _computeDefectStrengthFactor();
    final designWind = _parseNullable(_designWindController) ?? 40.0;
    final cavity = _parseNullable(_cavityController);
    
    // Calculate current residual wall info
    final currentWallPct = cavity != null && cavity > 0 
        ? ((dbh - cavity) / dbh) * 100 
        : 100.0;
    final currentWallThicknessCm = (dbh - (cavity ?? 0)) / 2;

    // Build failure threshold data for key wind speeds
    final thresholdData = <Map<String, dynamic>>[];
    final keyWindSpeeds = [25.0, 32.0, 40.0, 50.0, 60.0, 69.0];
    
    for (final windSpeed in keyWindSpeeds) {
      // Binary search for critical residual wall at this wind speed
      double lowRw = 10.0;
      double highRw = 100.0;
      double? criticalRw;
      double? criticalSF;
      
      for (var iter = 0; iter < 25; iter++) {
        final midRw = (lowRw + highRw) / 2.0;
        final frac = midRw / 100.0;
        final cavSimCm = dbh * (1.0 - frac);
        final sim = AusTreeCalcService.calculateSingle(
          species: _selectedSpecies,
          dbhCm: dbh,
          heightM: height,
          crownDiameterM: crown,
          designWindSpeedMs: windSpeed,
          cavityInnerDiameterCm: cavSimCm > 0 ? cavSimCm : null,
          crownFullnessOverride: _crownFullnessOverride,
          siteFactor: _siteFactor,
          defectStrengthFactor: defectFactor,
        );
        
        if (!sim.safetyFactor.isFinite) {
          lowRw = midRw;
          continue;
        }
        
        if ((sim.safetyFactor - 1.0).abs() < 0.01) {
          criticalRw = midRw;
          criticalSF = sim.safetyFactor;
          break;
        }
        
        if (sim.safetyFactor > 1.0) {
          highRw = midRw;
        } else {
          lowRw = midRw;
        }
        criticalRw = midRw;
        criticalSF = sim.safetyFactor;
      }
      
      if (criticalRw != null && criticalRw > 10 && criticalRw < 100) {
        final criticalWallCm = dbh * (criticalRw / 100.0) / 2.0;
        final decayTolerance = 100.0 - criticalRw;
        final wouldFail = currentWallPct < criticalRw;
        
        thresholdData.add({
          'windSpeed': windSpeed,
          'criticalRwPct': criticalRw,
          'criticalWallCm': criticalWallCm,
          'decayTolerance': decayTolerance,
          'wouldFail': wouldFail,
        });
      }
    }
    
    if (thresholdData.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpansionTile(
      title: const Text('Timber failure thresholds (detailed calculations)'),
      subtitle: const Text('Critical wall thickness at different wind speeds'),
      childrenPadding: const EdgeInsets.all(8),
      children: [
        // Current status summary
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Tree Status', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text('DBH: ${dbh.toStringAsFixed(1)} cm'),
                if (cavity != null && cavity > 0) ...[
                  Text('Cavity diameter: ${cavity.toStringAsFixed(1)} cm'),
                  Text('Residual wall: ${currentWallPct.toStringAsFixed(1)}% (${currentWallThicknessCm.toStringAsFixed(1)} cm per side)'),
                ] else
                  const Text('Residual wall: 100% (solid section)'),
                Text('Defect strength factor: ${defectFactor.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Failure threshold table
        Text('Critical Timber Requirements by Wind Speed', 
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey.shade400),
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.3),
            4: FlexColumnWidth(1.0),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Wind\n(m/s)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Min. Residual\nWall %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Min. Wall\nThickness', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Max. Decay\nTolerable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            ...thresholdData.map((data) {
              final windSpd = data['windSpeed'] as double;
              final isDesign = (windSpd - designWind).abs() < 1.0;
              final wouldFail = data['wouldFail'] as bool;
              return TableRow(
                decoration: BoxDecoration(
                  color: isDesign 
                      ? Colors.blue.shade100 
                      : wouldFail 
                          ? Colors.red.shade50 
                          : Colors.green.shade50,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '${windSpd.toStringAsFixed(0)}${isDesign ? ' ★' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isDesign ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '${(data['criticalRwPct'] as double).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '${(data['criticalWallCm'] as double).toStringAsFixed(1)} cm',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '${(data['decayTolerance'] as double).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      wouldFail ? Icons.warning : Icons.check_circle,
                      color: wouldFail ? Colors.red : Colors.green,
                      size: 18,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '★ = Design wind speed. Status shows if current tree would fail at that wind.',
          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
        
        const SizedBox(height: 16),
        
        // Calculation explanation
        ExpansionTile(
          title: const Text('How these values are calculated'),
          childrenPadding: const EdgeInsets.all(8),
          children: [
            SelectableText(
              '''FAILURE THRESHOLD CALCULATION METHOD

For each wind speed, we find the critical residual wall percentage where Safety Factor (SF) ≈ 1.0

The calculation uses:
1. Wind pressure: q = 0.5 × ρ × V² × Cd
   where ρ = 1.2 kg/m³, Cd = 1.2 (drag coefficient)

2. Wind force on crown: F = q × A_crown
   where A_crown = (π/4) × D_crown² × k_fullness

3. Bending moment at base: M = F × H × 0.7
   (0.7 accounts for distributed crown loading)

4. For hollow section with cavity:
   Section modulus Z = (π/32) × (D⁴ - d⁴) / D
   where D = DBH, d = cavity diameter

5. Bending stress: σ = M / Z

6. Safety factor: SF = fb × k_defect / σ
   where fb = species bending strength (${_selectedSpecies.fbGreenMPa.toStringAsFixed(1)} MPa)
   k_defect = ${defectFactor.toStringAsFixed(2)} (your defect factor)

CRITICAL RESIDUAL WALL:
We iterate to find the residual wall % where SF = 1.0 (failure threshold).
- Below this wall %, the tree will FAIL at that wind speed
- Above this wall %, the tree will SURVIVE at that wind speed

DECAY TOLERANCE:
Decay tolerance = 100% - Critical residual wall %
This is how much of the cross-section can decay before failure.

EXAMPLE at ${designWind.toStringAsFixed(0)} m/s design wind:
${_buildExampleCalculation(dbh, height, crown, designWind, defectFactor)}
''',
              style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ],
        ),
      ],
    );
  }

  String _buildExampleCalculation(double dbh, double height, double crown, double wind, double kDefect) {
    final rho = 1.2;
    final Cd = 1.2;
    final q = 0.5 * rho * wind * wind * Cd;
    final Acrown = 3.14159 / 4 * crown * crown * 0.7;
    final F = q * Acrown;
    final M = F * height * 0.7;
    final fb = _selectedSpecies.fbGreenMPa;
    
    // For solid section
    final D = dbh / 100; // convert to m
    final Z = 3.14159 / 32 * D * D * D * 1e6; // in mm³ → convert for display
    final sigma = M / (Z / 1e9); // MPa
    final SF = fb * kDefect / sigma;
    
    return '''
Wind pressure q = 0.5 × 1.2 × ${wind.toStringAsFixed(0)}² × 1.2 = ${q.toStringAsFixed(1)} Pa
Crown area A = π/4 × ${crown.toStringAsFixed(1)}² × 0.7 = ${Acrown.toStringAsFixed(2)} m²
Wind force F = ${q.toStringAsFixed(1)} × ${Acrown.toStringAsFixed(2)} = ${F.toStringAsFixed(1)} N = ${(F/1000).toStringAsFixed(2)} kN
Moment M = ${(F/1000).toStringAsFixed(2)} × ${height.toStringAsFixed(1)} × 0.7 = ${(M/1000).toStringAsFixed(2)} kN·m
Section modulus Z (solid) = π/32 × ${(D*1000).toStringAsFixed(0)}³ = ${(Z/1000).toStringAsFixed(0)} cm³
Bending stress σ = ${(M/1000).toStringAsFixed(2)} / ${(Z/1e6).toStringAsFixed(4)} = ${sigma.toStringAsFixed(2)} MPa
SF = ${fb.toStringAsFixed(1)} × ${kDefect.toStringAsFixed(2)} / ${sigma.toStringAsFixed(2)} = ${SF.toStringAsFixed(2)}''';
  }

  Widget _buildRootPlateCard(ThemeData theme) {
    final rootFactor = _computeRootPlateStabilityFactor();
    final riskRating = _getRootPlateRiskRating();
    final riskColor = rootFactor >= 0.9 ? const Color(0xFF4ade80)
        : rootFactor >= 0.7 ? const Color(0xFFfbbf24)
        : rootFactor >= 0.5 ? const Color(0xFFfb923c)
        : const Color(0xFFef4444);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildModernCardHeader('Root Plate Analysis', Icons.grass_rounded, const Color(0xFF8b5cf6), subtitle: 'Anchorage stability'),
                ),
                Switch(
                  value: _showRootPlateAnalysis,
                  activeColor: const Color(0xFF8b5cf6),
                  onChanged: (val) => setState(() => _showRootPlateAnalysis = val),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_showRootPlateAnalysis)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Enable to assess root plate stability', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
                  ],
                ),
              )
            else ...[
              // Risk rating display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [riskColor.withOpacity(0.15), riskColor.withOpacity(0.05)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: riskColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.foundation_rounded, color: riskColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(riskRating, style: TextStyle(color: riskColor, fontWeight: FontWeight.w700, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text('Stability Factor: ${rootFactor.toStringAsFixed(2)}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Soil conditions
              Text('Soil Type', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSoilChip('Rocky', 'rocky', Icons.terrain),
                  _buildSoilChip('Clay', 'clay', Icons.layers),
                  _buildSoilChip('Clay Loam', 'clay_loam', Icons.landscape),
                  _buildSoilChip('Loam', 'loam', Icons.eco),
                  _buildSoilChip('Sandy', 'sandy', Icons.grain),
                  _buildSoilChip('Organic', 'organic', Icons.compost),
                ],
              ),
              const SizedBox(height: 16),
              
              Text('Soil Moisture', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMoistureChip('Dry', 'dry'),
                  _buildMoistureChip('Moist', 'moist'),
                  _buildMoistureChip('Wet', 'wet'),
                  _buildMoistureChip('Waterlogged', 'waterlogged'),
                ],
              ),
              const SizedBox(height: 20),
              
              // Lean angle
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lean Angle: ${_leanAngleDegrees.toStringAsFixed(0)}°', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                        Slider(
                          value: _leanAngleDegrees,
                          min: 0,
                          max: 25,
                          divisions: 25,
                          onChanged: (v) => setState(() => _leanAngleDegrees = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Checkboxes for conditions
              _buildRootCheckbox('Recent lean change observed', _recentLeanChange, (v) => setState(() => _recentLeanChange = v ?? false)),
              _buildRootCheckbox('Heaving/cracking around base', _heavingCracking, (v) => setState(() => _heavingCracking = v ?? false)),
              _buildRootCheckbox('Root decay present', _rootDecay, (v) => setState(() => _rootDecay = v ?? false)),
              
              // Severed roots
              _buildRootCheckbox('Severed/damaged roots', _severedRoots, (v) => setState(() => _severedRoots = v ?? false)),
              if (_severedRoots) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('% of roots affected: ${_severedRootsPercent.toStringAsFixed(0)}%', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                      Slider(
                        value: _severedRootsPercent,
                        min: 0,
                        max: 80,
                        divisions: 16,
                        onChanged: (v) => setState(() => _severedRootsPercent = v),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Restricted root zone
              _buildRootCheckbox('Restricted root zone', _restrictedRootZone, (v) => setState(() => _restrictedRootZone = v ?? false)),
              if (_restrictedRootZone) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildRestrictionChip('Pavement', 'pavement'),
                      _buildRestrictionChip('Building', 'building'),
                      _buildRestrictionChip('Wall', 'wall'),
                      _buildRestrictionChip('Excavation', 'excavation'),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              // Optional measurements
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rootPlateRadiusController,
                      decoration: const InputDecoration(
                        labelText: 'Root plate radius (m)',
                        hintText: 'e.g. 3.5',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _rootPlateDepthController,
                      decoration: const InputDecoration(
                        labelText: 'Root plate depth (m)',
                        hintText: 'e.g. 0.6',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSoilChip(String label, String value, IconData icon) {
    final selected = _soilType == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : Colors.white54),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (sel) => setState(() => _soilType = value),
      selectedColor: const Color(0xFF8b5cf6),
    );
  }

  Widget _buildMoistureChip(String label, String value) {
    final selected = _soilMoisture == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (sel) => setState(() => _soilMoisture = value),
      selectedColor: const Color(0xFF22d3ee),
    );
  }

  Widget _buildRestrictionChip(String label, String value) {
    final selected = _rootZoneRestriction == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (sel) => setState(() => _rootZoneRestriction = value),
      selectedColor: const Color(0xFFfb923c),
    );
  }

  Widget _buildRootCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF8b5cf6),
          ),
          Expanded(child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8)))),
        ],
      ),
    );
  }

  Widget _buildLiveSimulatorCard(ThemeData theme) {
    final result = _mainResult;
    if (result == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildModernCardHeader('Live Simulator', Icons.animation_rounded, const Color(0xFFfb923c), subtitle: 'Pending calculation'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Run a calculation first', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dbh = _parseNullable(_dbhController);
    final height = _parseNullable(_heightController);
    final crown = _parseNullable(_crownDiameterController);
    final wind = _parseNullable(_designWindController);
    final cavity = _parseNullable(_cavityController);

    if (dbh == null || height == null || crown == null || wind == null) {
      return const SizedBox.shrink();
    }

    final defectFactor = _computeDefectStrengthFactor();

    return LiveWindLoadSimulator(
      dbhCm: dbh,
      heightM: height,
      crownDiameterM: crown,
      cavityDiameterCm: cavity,
      speciesStrengthMPa: _selectedSpecies.fbGreenMPa,
      defectFactor: defectFactor,
      siteFactor: _siteFactor,
      designWindSpeed: wind,
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildPruningCard(ThemeData theme) {
    final pruning = _pruningResult;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildModernCardHeader('Pruning', Icons.content_cut_rounded, const Color(0xFF8b5cf6), subtitle: 'Crown reduction'),
                ),
                Switch(
                  value: _simulatePruning,
                  activeColor: const Color(0xFF8b5cf6),
                  onChanged: (val) {
                    setState(() {
                      _simulatePruning = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_simulatePruning)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Enable switch to simulate crown reduction', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
                  ],
                ),
              ),
            if (_simulatePruning) ...[
              Text(
                'Crown diameter reduction (%)',
                style: theme.textTheme.bodyMedium,
              ),
              Slider(
                value: _crownDiameterReductionPercent,
                min: 0,
                max: 40,
                divisions: 8,
                label: _crownDiameterReductionPercent.toStringAsFixed(0),
                onChanged: (v) {
                  setState(() {
                    _crownDiameterReductionPercent = v;
                  });
                },
              ),
              Text(
                'Crown thinning (fullness reduction, %)',
                style: theme.textTheme.bodyMedium,
              ),
              Slider(
                value: _fullnessReductionPercent,
                min: 0,
                max: 60,
                divisions: 12,
                label: _fullnessReductionPercent.toStringAsFixed(0),
                onChanged: (v) {
                  setState(() {
                    _fullnessReductionPercent = v;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Recalculate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _mainResult != null ? _onCalculate : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recalculate with Pruning'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (pruning == null)
                Text(
                  'Adjust sliders and click "Recalculate with Pruning" to see before/after results.',
                  style: theme.textTheme.bodyMedium,
                )
              else
                _buildPruningSummary(theme, pruning),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPruningSummary(
      ThemeData theme, PruningScenarioResult pruning) {
    final sfBefore = pruning.before.safetyFactor;
    final sfAfter = pruning.after.safetyFactor;
    final improvement =
        sfBefore > 0 && sfBefore.isFinite && sfAfter.isFinite
            ? ((sfAfter - sfBefore) / sfBefore) * 100.0
            : double.nan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Before vs after (retention with mitigation)',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _detailRow(
          'Crown diameter',
          '${pruning.crownDiameterBeforeM.toStringAsFixed(1)} m → '
          '${pruning.crownDiameterAfterM.toStringAsFixed(1)} m',
        ),
        _detailRow(
          'Effective crown fullness',
          '${(pruning.fullnessBefore * 100).toStringAsFixed(0)}% → '
          '${(pruning.fullnessAfter * 100).toStringAsFixed(0)}%',
        ),
        const SizedBox(height: 8),
        _detailRow(
          'SF before',
          sfBefore.isFinite ? sfBefore.toStringAsFixed(2) : '∞',
        ),
        _detailRow(
          'SF after',
          sfAfter.isFinite ? sfAfter.toStringAsFixed(2) : '∞',
        ),
        _detailRow(
          'Bending stress before',
          '${pruning.before.bendingStressMPa.toStringAsFixed(2)} MPa',
        ),
        _detailRow(
          'Bending stress after',
          '${pruning.after.bendingStressMPa.toStringAsFixed(2)} MPa',
        ),
        const SizedBox(height: 8),
        Text(
          improvement.isFinite
              ? 'Estimated structural margin improvement: '
                  '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(0)}%.'
              : 'Estimated structural margin improvement: not available.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        PruningSimulationVisual(
          heightM: _parseNullable(_heightController) ?? 10.0,
          crownBeforeM: pruning.crownDiameterBeforeM,
          crownAfterM: pruning.crownDiameterAfterM,
          fullnessBefore: pruning.fullnessBefore,
          fullnessAfter: pruning.fullnessAfter,
        ),
        const SizedBox(height: 12),
        ReductionEffectGraph(
          reductionsPercent: _reductionPercents,
          safetyFactors: _reductionSafetyFactors,
          currentReductionPercent: _crownDiameterReductionPercent,
          sfBefore: pruning.before.safetyFactor,
          sfAfter: pruning.after.safetyFactor,
        ),
      ],
    );
  }

  Widget _buildReportCard(ThemeData theme) {
    final hasReport =
        _shortSummary.trim().isNotEmpty || _technicalAppendix.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernCardHeader('Report', Icons.article_rounded, const Color(0xFF60a5fa), subtitle: 'AS 4970-aligned output'),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _mainResult == null ? null : _onGenerateReport,
                  icon: const Icon(Icons.description_rounded, size: 18),
                  label: const Text('Generate'),
                ),
                OutlinedButton.icon(
                  onPressed: hasReport ? _copyReportToClipboard : null,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _mainResult == null ? null : _onExportJson,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('JSON'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                ),
                FilledButton.icon(
                  onPressed: hasReport ? _onExportWord : null,
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Word/HTML'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563eb),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasReport)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Generate a report after calculation', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
                  ],
                ),
              )
            else ...[
              SelectableText(
                '${_shortSummary.trim()}\n\n$_technicalAppendix',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (_mainResult != null) ...[
                Text(
                  'Report figures (preview)',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SafetyFactorVsWindGraph(
                  windSpeeds: _sfWindSpeeds,
                  safetyFactors: _sfWindSafetyFactors,
                  designWindSpeed: _parseNullable(_designWindController),
                  windToFailure: _windToFailureMs,
                ),
                const SizedBox(height: 12),
                ResidualWallGraph(
                  residualWallPercents: _residualWallPercents,
                  safetyFactors: _residualWallSafetyFactors,
                  currentResidualPercent: _decayCurrentResidualPercent,
                  criticalResidualPercent: _decayCriticalResidualPercent,
                ),
                const SizedBox(height: 12),
                ReductionEffectGraph(
                  reductionsPercent: _reductionPercents,
                  safetyFactors: _reductionSafetyFactors,
                  currentReductionPercent: _simulatePruning ? _crownDiameterReductionPercent : null,
                  sfBefore: _pruningResult?.before.safetyFactor,
                  sfAfter: _pruningResult?.after.safetyFactor,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMethodologyCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ExpansionTile(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 28),
          ),
          title: const Text(
            'Methodology & References',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Scientific basis & calculation methods',
              style: TextStyle(color: Color(0xFF94a3b8), fontSize: 14),
            ),
          ),
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white70,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1e1e30), Color(0xFF0f0f1a)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3b82f6).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF60a5fa), size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text('Overview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'AusTreeCalc uses static biomechanical analysis to estimate the structural safety margin of trees under wind loading, based on AS 4970-2009 and peer-reviewed research.',
                          style: TextStyle(color: Color(0xFFcbd5e1), height: 1.6, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Formulas section
                  _buildSectionTitle('Calculations', const Color(0xFFa78bfa)),
                  const SizedBox(height: 12),
                  _buildFormulaRow('q', 'Wind Pressure', '0.5 × ρ × V²', const Color(0xFFf472b6)),
                  _buildFormulaRow('F', 'Wind Force', 'q × Cd × A', const Color(0xFFfb7185)),
                  _buildFormulaRow('M', 'Bending Moment', 'F × h_eff', const Color(0xFFfb923c)),
                  _buildFormulaRow('W', 'Section Modulus', 'π(D⁴-d⁴)/32D', const Color(0xFFfbbf24)),
                  _buildFormulaRow('σ', 'Bending Stress', 'M / W', const Color(0xFF4ade80)),
                  _buildFormulaRow('SF', 'Safety Factor', 'f_b / σ', const Color(0xFF22d3ee)),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Parameters', const Color(0xFF4ade80)),
                  const SizedBox(height: 12),
                  _buildParamPill('Cd', '0.3–0.5', 'Drag coefficient'),
                  _buildParamPill('f_b', '20–50 MPa', 'Wood strength'),
                  _buildParamPill('h_eff', '0.66 × H', 'Effective height'),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('References', const Color(0xFF60a5fa)),
                  const SizedBox(height: 12),
                  _buildRefCard('AS 4970-2009', 'Protection of trees on development sites', true),
                  _buildRefCard('Mattheck & Breloer', 'The Body Language of Trees (1994)', false),
                  _buildRefCard('Niklas, K.J.', 'Plant Biomechanics (1992)', false),
                  _buildRefCard('James et al.', 'Mechanical stability under dynamic loads (2006)', true),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Wind Guide', const Color(0xFF22d3ee)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildWindPill('25-40', 'Strong', const Color(0xFFfbbf24))),
                      const SizedBox(width: 10),
                      Expanded(child: _buildWindPill('40-50', 'Severe', const Color(0xFFfb923c))),
                      const SizedBox(width: 10),
                      Expanded(child: _buildWindPill('50+', 'Cyclone', const Color(0xFFef4444))),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFef4444).withOpacity(0.15), const Color(0xFFf97316).withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFef4444).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFef4444).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.warning_rounded, color: Color(0xFFfca5a5), size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Disclaimer', style: TextStyle(color: Color(0xFFfca5a5), fontWeight: FontWeight.w600, fontSize: 14)),
                              SizedBox(height: 4),
                              Text(
                                'This is a simplified static model. Results are estimates only and do not replace professional arborist assessment.',
                                style: TextStyle(color: Color(0xFFfecaca), fontSize: 12, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCardHeader(String title, IconData icon, Color color, {String? subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormulaRow(String symbol, String name, String formula, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.8), color],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Center(
              child: Text(symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Color(0xFFe2e8f0), fontWeight: FontWeight.w500, fontSize: 13)),
                const SizedBox(height: 2),
                Text(formula, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamPill(String symbol, String value, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4ade80).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(symbol, style: const TextStyle(color: Color(0xFF4ade80), fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRefCard(String title, String desc, bool hasLink) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF60a5fa).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(hasLink ? Icons.link_rounded : Icons.menu_book_rounded, color: const Color(0xFF60a5fa), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(desc, style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 11)),
              ],
            ),
          ),
          if (hasLink)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3b82f6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('DOI', style: TextStyle(color: Color(0xFF60a5fa), fontSize: 10, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildWindPill(String speed, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(speed, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 2),
          Text('m/s', style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

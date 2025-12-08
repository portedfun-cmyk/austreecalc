import '../models/species_preset.dart';

/// Hard-coded species presets for AusTreeCalc.
class SpeciesPresets {
  static const SpeciesPreset eucHigh = SpeciesPreset(
    id: 'euc_high',
    displayName: 'Eucalypt – High Strength (ironbark / spotted gum type)',
    fbGreenMPa: 50.0,
    dragCoefficient: 0.25,
    crownShapeFactor: 0.7,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset eucTypical = SpeciesPreset(
    id: 'euc_typical',
    displayName: 'Eucalypt – Typical Street Tree',
    fbGreenMPa: 35.0,
    dragCoefficient: 0.25,
    crownShapeFactor: 0.7,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset broadleafDeciduous = SpeciesPreset(
    id: 'broadleaf_deciduous',
    displayName: 'Broadleaf – Plane / Elm / Oak',
    fbGreenMPa: 28.0,
    dragCoefficient: 0.30,
    crownShapeFactor: 0.75,
    defaultFullness: 0.95,
  );

  static const SpeciesPreset coniferSoftwood = SpeciesPreset(
    id: 'conifer_softwood',
    displayName: 'Conifer – Pine / Cypress',
    fbGreenMPa: 20.0,
    dragCoefficient: 0.35,
    crownShapeFactor: 0.8,
    defaultFullness: 1.0,
  );

  static const SpeciesPreset araucaria = SpeciesPreset(
    id: 'araucaria',
    displayName: 'Araucaria – Norfolk Island Pine',
    fbGreenMPa: 24.0,
    dragCoefficient: 0.30,
    crownShapeFactor: 0.7,
    defaultFullness: 0.95,
  );

  static const SpeciesPreset unknownHardwood = SpeciesPreset(
    id: 'unknown_hardwood',
    displayName: 'Unknown Hardwood (broadleaf)',
    fbGreenMPa: 25.0,
    dragCoefficient: 0.28,
    crownShapeFactor: 0.7,
    defaultFullness: 0.9,
  );

  static const SpeciesPreset unknownSoftwood = SpeciesPreset(
    id: 'unknown_softwood',
    displayName: 'Unknown Softwood / Evergreen',
    fbGreenMPa: 18.0,
    dragCoefficient: 0.33,
    crownShapeFactor: 0.75,
    defaultFullness: 0.95,
  );

  static final Map<String, SpeciesPreset> all = {
    eucHigh.id: eucHigh,
    eucTypical.id: eucTypical,
    broadleafDeciduous.id: broadleafDeciduous,
    coniferSoftwood.id: coniferSoftwood,
    araucaria.id: araucaria,
    unknownHardwood.id: unknownHardwood,
    unknownSoftwood.id: unknownSoftwood,
  };

  static List<SpeciesPreset> get list => all.values.toList(growable: false);
}

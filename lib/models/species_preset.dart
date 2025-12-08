/// Species group preset used for tree statics calculations.
///
/// fbGreenMPa: nominal green bending strength (MPa)
/// dragCoefficient: Cd (dimensionless)
/// crownShapeFactor: kA (dimensionless)
/// defaultFullness: 0–1 crown fullness (dimensionless)
class SpeciesPreset {
  final String id;
  final String displayName;
  final double fbGreenMPa;
  final double dragCoefficient;
  final double crownShapeFactor;
  final double defaultFullness;

  const SpeciesPreset({
    required this.id,
    required this.displayName,
    required this.fbGreenMPa,
    required this.dragCoefficient,
    required this.crownShapeFactor,
    required this.defaultFullness,
  });
}

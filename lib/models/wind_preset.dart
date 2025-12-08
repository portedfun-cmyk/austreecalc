/// Wind preset approximating Australian wind regions / exposure.
///
/// designWindSpeedMs is the design gust at tree height (m/s).
class WindPreset {
  final String id;
  final String displayName;
  final double designWindSpeedMs;

  const WindPreset({
    required this.id,
    required this.displayName,
    required this.designWindSpeedMs,
  });
}

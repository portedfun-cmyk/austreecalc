import '../models/wind_preset.dart';

/// Australian wind region / exposure presets.
class WindPresets {
  static const WindPreset regionAUrban = WindPreset(
    id: 'A_urban',
    displayName: 'Region A – Urban/Suburban',
    designWindSpeedMs: 35.0,
  );
  static const WindPreset regionAOpen = WindPreset(
    id: 'A_open',
    displayName: 'Region A – Open/Exposed',
    designWindSpeedMs: 40.0,
  );
  static const WindPreset regionBUrban = WindPreset(
    id: 'B_urban',
    displayName: 'Region B – Urban/Suburban',
    designWindSpeedMs: 40.0,
  );
  static const WindPreset regionBOpen = WindPreset(
    id: 'B_open',
    displayName: 'Region B – Open/Exposed',
    designWindSpeedMs: 45.0,
  );
  static const WindPreset regionCUrban = WindPreset(
    id: 'C_urban',
    displayName: 'Region C – Urban/Suburban',
    designWindSpeedMs: 50.0,
  );
  static const WindPreset regionCOpen = WindPreset(
    id: 'C_open',
    displayName: 'Region C – Open/Exposed',
    designWindSpeedMs: 55.0,
  );
  static const WindPreset regionDUrban = WindPreset(
    id: 'D_urban',
    displayName: 'Region D – Urban/Suburban',
    designWindSpeedMs: 55.0,
  );
  static const WindPreset regionDOpen = WindPreset(
    id: 'D_open',
    displayName: 'Region D – Open/Exposed',
    designWindSpeedMs: 60.0,
  );

  static final Map<String, WindPreset> all = {
    regionAUrban.id: regionAUrban,
    regionAOpen.id: regionAOpen,
    regionBUrban.id: regionBUrban,
    regionBOpen.id: regionBOpen,
    regionCUrban.id: regionCUrban,
    regionCOpen.id: regionCOpen,
    regionDUrban.id: regionDUrban,
    regionDOpen.id: regionDOpen,
  };

  static List<WindPreset> get list => all.values.toList(growable: false);
}

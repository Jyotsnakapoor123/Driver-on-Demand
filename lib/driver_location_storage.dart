import 'package:shared_preferences/shared_preferences.dart';

class DriverLocationStorage {
  static const String _latitudeKey = 'driver_latitude';
  static const String _longitudeKey = 'driver_longitude';

  static Future<void> saveLocation({
    required double latitude,
    required double longitude,
  }) async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setDouble(
      _latitudeKey,
      latitude,
    );

    await preferences.setDouble(
      _longitudeKey,
      longitude,
    );
  }

  static Future<Map<String, double>?> getLocation() async {
    final preferences =
        await SharedPreferences.getInstance();

    final latitude =
        preferences.getDouble(_latitudeKey);

    final longitude =
        preferences.getDouble(_longitudeKey);

    if (latitude == null || longitude == null) {
      return null;
    }

    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static Future<void> clearLocation() async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.remove(_latitudeKey);
    await preferences.remove(_longitudeKey);
  }
}
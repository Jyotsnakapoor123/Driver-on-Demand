import 'package:shared_preferences/shared_preferences.dart';

class DriverAvailabilityStorage {
  static const String _availabilityKey = 'driver_is_available';

  static Future<bool> isAvailable() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getBool(_availabilityKey) ?? false;
  }

  static Future<void> setAvailable(bool value) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(
      _availabilityKey,
      value,
    );
  }
}
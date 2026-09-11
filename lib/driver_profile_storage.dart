import 'package:shared_preferences/shared_preferences.dart';

class DriverProfileStorage {
  static const String _nameKey = 'driver_name';
  static const String _emailKey = 'driver_email';
  static const String _phoneKey = 'driver_phone';

  static const String defaultName = 'Driver Name';
  static const String defaultEmail = 'driver@email.com';
  static const String defaultPhone = '';

  static Future<Map<String, String>> loadProfile() async {
    final preferences = await SharedPreferences.getInstance();

    return {
      'name': preferences.getString(_nameKey) ?? defaultName,
      'email': preferences.getString(_emailKey) ?? defaultEmail,
      'phone': preferences.getString(_phoneKey) ?? defaultPhone,
    };
  }

  static Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_nameKey, name);
    await preferences.setString(_emailKey, email);
    await preferences.setString(_phoneKey, phone);
  }
}
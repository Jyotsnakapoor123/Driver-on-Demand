import 'package:shared_preferences/shared_preferences.dart';
import 'driver_auth_storage.dart';

class DriverProfileStorage {
  static const String _nameKey = 'driver_name';
  static const String _emailKey = 'driver_email';
  static const String _phoneKey = 'driver_phone';

  static const String defaultName = 'Driver Name';
  static const String defaultEmail = 'driver@email.com';
  static const String defaultPhone = '';

  static String _key(
    String baseKey,
    String email,
  ) {
    return '${baseKey}_${email.toLowerCase().trim()}';
  }

  static Future<Map<String, String>> loadProfile() async {
    final preferences =
        await SharedPreferences.getInstance();

    final loggedInEmail =
        await DriverAuthStorage.getLoggedInEmail();

    if (loggedInEmail == null ||
        loggedInEmail.trim().isEmpty) {
      return {
        'name': defaultName,
        'email': defaultEmail,
        'phone': defaultPhone,
      };
    }

    final email = loggedInEmail.toLowerCase().trim();

    return {
      'name':
          preferences.getString(
            _key(_nameKey, email),
          ) ??
          defaultName,

      'email':
          preferences.getString(
            _key(_emailKey, email),
          ) ??
          email,

      'phone':
          preferences.getString(
            _key(_phoneKey, email),
          ) ??
          defaultPhone,
    };
  }

  static Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final preferences =
        await SharedPreferences.getInstance();

    final normalizedEmail =
        email.toLowerCase().trim();

    await preferences.setString(
      _key(_nameKey, normalizedEmail),
      name.trim(),
    );

    await preferences.setString(
      _key(_emailKey, normalizedEmail),
      normalizedEmail,
    );

    await preferences.setString(
      _key(_phoneKey, normalizedEmail),
      phone.trim(),
    );
  }
}
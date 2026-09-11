import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _emailKey = 'auth_email';
  static const String _passwordKey = 'auth_password';
  static const String _loggedInKey = 'is_logged_in';

  static Future<bool> hasAccount() async {
    final preferences = await SharedPreferences.getInstance();

    final email = preferences.getString(_emailKey);
    final password = preferences.getString(_passwordKey);

    return email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    final savedEmail = preferences.getString(_emailKey);
    final savedPassword = preferences.getString(_passwordKey);

    if (savedEmail == email && savedPassword == password) {
      await preferences.setBool(_loggedInKey, true);
      return true;
    }

    return false;
  }

  static Future<void> signup({
    required String email,
    required String password,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_emailKey, email);
    await preferences.setString(_passwordKey, password);
    await preferences.setBool(_loggedInKey, true);
  }

  static Future<bool> isLoggedIn() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getBool(_loggedInKey) ?? false;
  }

  static Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_loggedInKey, false);
  }
}
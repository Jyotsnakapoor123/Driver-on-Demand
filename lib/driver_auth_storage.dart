import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DriverAuthStorage {
  static const String _accountsKey = 'driver_accounts';
  static const String _loggedInKey = 'driver_is_logged_in';
  static const String _loggedInEmailKey = 'driver_logged_in_email';

  static Future<List<Map<String, String>>> _getAccounts() async {
    final preferences = await SharedPreferences.getInstance();

    final data = preferences.getString(_accountsKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(data);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .map<Map<String, String>>(
          (account) => Map<String, String>.from(account),
        )
        .toList();
  }

  static Future<void> _saveAccounts(
    List<Map<String, String>> accounts,
  ) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _accountsKey,
      jsonEncode(accounts),
    );
  }

  static Future<bool> hasAccount({
    required String email,
  }) async {
    final accounts = await _getAccounts();

    return accounts.any(
      (account) =>
          account['email']?.toLowerCase() == email.toLowerCase(),
    );
  }

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final accounts = await _getAccounts();

    final account = accounts.cast<Map<String, String>?>().firstWhere(
      (account) =>
          account?['email']?.toLowerCase() == email.toLowerCase() &&
          account?['password'] == password,
      orElse: () => null,
    );

    if (account != null) {
      final preferences = await SharedPreferences.getInstance();

      await preferences.setBool(
        _loggedInKey,
        true,
      );

      await preferences.setString(
        _loggedInEmailKey,
        email,
      );

      return true;
    }

    return false;
  }

  static Future<void> signup({
    required String email,
    required String password,
  }) async {
    final accounts = await _getAccounts();

    accounts.add({
      'email': email.trim(),
      'password': password,
    });

    await _saveAccounts(accounts);

    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(
      _loggedInKey,
      true,
    );

    await preferences.setString(
      _loggedInEmailKey,
      email.trim(),
    );
  }

  static Future<bool> isLoggedIn() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getBool(_loggedInKey) ?? false;
  }

  static Future<String?> getLoggedInEmail() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_loggedInEmailKey);
  }

  static Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(
      _loggedInKey,
      false,
    );

    await preferences.remove(
      _loggedInEmailKey,
    );
  }
}
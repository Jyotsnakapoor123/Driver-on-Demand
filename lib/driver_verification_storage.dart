import 'package:shared_preferences/shared_preferences.dart';

class DriverVerificationStorage {
  static const String _statusKey = 'driver_verification_status';
  static const String _licenseKey = 'driver_license_number';
  static const String _vehicleKey = 'driver_vehicle_number';

  static const String statusNotSubmitted = 'not_submitted';
  static const String statusPending = 'pending';
  static const String statusVerified = 'verified';
  static const String statusRejected = 'rejected';

  static Future<String> getStatus() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_statusKey) ??
        statusNotSubmitted;
  }

  static Future<String?> getLicenseNumber() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_licenseKey);
  }

  static Future<String?> getVehicleNumber() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_vehicleKey);
  }

  static Future<void> submitVerification({
    required String licenseNumber,
    required String vehicleNumber,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _licenseKey,
      licenseNumber,
    );

    await preferences.setString(
      _vehicleKey,
      vehicleNumber,
    );

    await preferences.setString(
      _statusKey,
      statusPending,
    );
  }
}
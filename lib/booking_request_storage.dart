import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'profile_storage.dart';

class BookingRequestStorage {
  static const String _requestsKey = 'booking_requests';

  static Future<List<Map<String, dynamic>>> getRequests() async {
    final preferences = await SharedPreferences.getInstance();

    final savedRequests =
        preferences.getStringList(_requestsKey) ?? [];

    return savedRequests.map((request) {
      return Map<String, dynamic>.from(
        jsonDecode(request) as Map,
      );
    }).toList();
  }

  static Future<void> saveRequest({
    required String driverName,
    required double driverRating,
    required int hourlyRate,
    required int hours,
    required String pickupAddress,
    required String selectedDate,
    required String selectedTime,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    final requests = await getRequests();

    final profile = await ProfileStorage.loadProfile();

    final customerName =
        profile['name'] ?? 'Customer';

    final request = {
      'id': 'REQ${DateTime.now().millisecondsSinceEpoch}',
      'customerName': customerName,
      'driverName': driverName,
      'driverRating': driverRating,
      'hourlyRate': hourlyRate,
      'hours': hours,
      'totalFare': hourlyRate * hours,
      'pickupAddress': pickupAddress,
      'selectedDate': selectedDate,
      'selectedTime': selectedTime,
      'status': 'requested',
      'createdAt': DateTime.now().toIso8601String(),
    };

    requests.add(request);

    await preferences.setStringList(
      _requestsKey,
      requests.map(jsonEncode).toList(),
    );
  }

  static Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    final requests = await getRequests();

    final index = requests.indexWhere(
      (request) => request['id'] == requestId,
    );

    if (index == -1) {
      return;
    }

    requests[index]['status'] = status;

    await preferences.setStringList(
      _requestsKey,
      requests.map(jsonEncode).toList(),
    );
  }

  static Future<void> clearRequests() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_requestsKey);
  }
}
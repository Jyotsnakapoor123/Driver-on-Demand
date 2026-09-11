import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DriverRideRequestStorage {
  static const String _requestsKey = 'driver_ride_requests';

  static Future<List<Map<String, dynamic>>> getRequests() async {
    final preferences = await SharedPreferences.getInstance();

    final savedRequests =
        preferences.getStringList(_requestsKey);

    if (savedRequests == null || savedRequests.isEmpty) {
      return [];
    }

    return savedRequests
        .map(
          (request) =>
              jsonDecode(request) as Map<String, dynamic>,
        )
        .toList();
  }

  static Future<void> saveRequests(
    List<Map<String, dynamic>> requests,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    final encodedRequests = requests
        .map((request) => jsonEncode(request))
        .toList();

    await preferences.setStringList(
      _requestsKey,
      encodedRequests,
    );
  }

  static Future<void> addDemoRequest() async {
    final requests = await getRequests();

    if (requests.isNotEmpty) {
      return;
    }

    final demoRequest = {
      'id': 'REQ1001',
      'customerName': 'Rahul Sharma',
      'pickup': 'Ganaur, Haryana',
      'destination': 'Panipat, Haryana',
      'date': '12 September 2026',
      'time': '10:30 AM',
      'duration': '4 hours',
      'fare': '₹1,200',
      'status': 'pending',
    };

    requests.add(demoRequest);

    await saveRequests(requests);
  }

  static Future<void> clearRequests() async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.remove(_requestsKey);
  }
}
import 'package:flutter/material.dart';

import 'driver_ride_request_storage.dart';

class DriverRideRequestsScreen extends StatefulWidget {
  const DriverRideRequestsScreen({super.key});

  @override
  State<DriverRideRequestsScreen> createState() =>
      _DriverRideRequestsScreenState();
}

class _DriverRideRequestsScreenState
    extends State<DriverRideRequestsScreen> {
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    await DriverRideRequestStorage.addDemoRequest();

    final savedRequests =
        await DriverRideRequestStorage.getRequests();

    if (!mounted) {
      return;
    }

    setState(() {
      requests = savedRequests
          .where(
            (request) =>
                request['status'] == 'pending',
          )
          .toList();

      isLoading = false;
    });
  }

  Future<void> _refreshRequests() async {
    setState(() {
      isLoading = true;
    });

    await _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ride Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _refreshRequests,

        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : requests.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: 220,
                      ),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No ride requests',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'New ride requests will appear here.',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      return _RideRequestCard(
                        request: requests[index],
                      );
                    },
                  ),
      ),
    );
  }
}

class _RideRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;

  const _RideRequestCard({
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // Request Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Ride Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      request['customerName'] ??
                          'Customer',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Pickup
          _LocationRow(
            icon: Icons.trip_origin,
            title: 'Pickup',
            value: request['pickup'] ?? 'Not available',
          ),

          const SizedBox(height: 14),

          // Destination
          _LocationRow(
            icon: Icons.location_on_outlined,
            title: 'Destination',
            value:
                request['destination'] ?? 'Not available',
          ),

          const Divider(
            height: 30,
          ),

          // Date
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            title: 'Date',
            value: request['date'] ?? '-',
          ),

          const SizedBox(height: 12),

          // Time
          _InfoRow(
            icon: Icons.access_time,
            title: 'Time',
            value: request['time'] ?? '-',
          ),

          const SizedBox(height: 12),

          // Duration
          _InfoRow(
            icon: Icons.timer_outlined,
            title: 'Duration',
            value: request['duration'] ?? '-',
          ),

          const SizedBox(height: 12),

          // Fare
          _InfoRow(
            icon: Icons.currency_rupee,
            title: 'Estimated Fare',
            value: request['fare'] ?? '-',
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Text(
              'Request ID: ${request['id'] ?? '-'}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,

            child: OutlinedButton(
              onPressed: () {},
              child: const Text(
                'VIEW REQUEST',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _LocationRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Icon(
          icon,
          size: 24,
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: Colors.grey.shade700,
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
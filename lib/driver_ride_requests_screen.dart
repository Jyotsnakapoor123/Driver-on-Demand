import 'package:flutter/material.dart';
import 'booking_request_storage.dart';
import 'driver_profile_storage.dart';

class DriverRideRequestsScreen extends StatefulWidget {
  const DriverRideRequestsScreen({
    super.key,
  });

  @override
  State<DriverRideRequestsScreen> createState() =>
      _DriverRideRequestsScreenState();
}

class _DriverRideRequestsScreenState
    extends State<DriverRideRequestsScreen> {
  List<Map<String, dynamic>> requests = [];

  bool isLoading = true;

  String currentDriverName = '';

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    final profile =
        await DriverProfileStorage.loadProfile();

    final driverName =
        profile['name']?.trim() ?? '';

    final allRequests =
        await BookingRequestStorage.getRequests();

    if (!mounted) return;

    setState(() {
      currentDriverName = driverName;

      requests = allRequests.where((request) {
        final status =
            request['status']?.toString() ?? '';

        final assignedDriver =
            request['driverName']?.toString().trim() ?? '';

        return status == 'requested' &&
            assignedDriver.toLowerCase() ==
                driverName.toLowerCase();
      }).toList();

      isLoading = false;
    });
  }

  Future<void> acceptRequest(
    Map<String, dynamic> request,
  ) async {
    await BookingRequestStorage.updateRequestStatus(
      requestId: request['id'] as String,
      status: 'accepted',
    );

    if (!mounted) return;

    setState(() {
      requests.remove(request);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ride request accepted successfully.',
        ),
      ),
    );
  }

  Future<void> rejectRequest(
    Map<String, dynamic> request,
  ) async {
    await BookingRequestStorage.updateRequestStatus(
      requestId: request['id'] as String,
      status: 'rejected',
    );

    if (!mounted) return;

    setState(() {
      requests.remove(request);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ride request rejected.',
        ),
      ),
    );
  }

  void viewRequest(
    Map<String, dynamic> request,
  ) {
    final customerName =
        request['customerName'] ?? 'Customer';

    final driverName =
        request['driverName'] ?? 'Driver';

    final pickupAddress =
        request['pickupAddress'] ?? 'Pickup location';

    final date =
        request['selectedDate'] ?? '';

    final time =
        request['selectedTime'] ?? '';

    final hours =
        request['hours'] ?? 1;

    final hourlyRate =
        request['hourlyRate'] ?? 0;

    final totalFare =
        request['totalFare'] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),

          title: const Text(
            'Ride Request',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                _DetailRow(
                  label: 'Customer',
                  value: customerName.toString(),
                ),

                const SizedBox(height: 12),

                _DetailRow(
                  label: 'Driver',
                  value: driverName.toString(),
                ),

                const SizedBox(height: 12),

                _DetailRow(
                  label: 'Pickup',
                  value: pickupAddress.toString(),
                ),

                const SizedBox(height: 12),

                _DetailRow(
                  label: 'Date',
                  value: date.toString(),
                ),

                const SizedBox(height: 12),

                _DetailRow(
                  label: 'Time',
                  value: time.toString(),
                ),

                const SizedBox(height: 12),

                _DetailRow(
                  label: 'Duration',
                  value:
                      '$hours ${hours == 1 ? 'hour' : 'hours'}',
                ),

                const SizedBox(height: 12),

                _DetailRow(
                  label: 'Hourly charge',
                  value: '₹$hourlyRate/hr',
                ),

                const Divider(
                  height: 28,
                ),

                _DetailRow(
                  label: 'Estimated fare',
                  value: '₹$totalFare',
                  bold: true,
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CLOSE'),
            ),

            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                await rejectRequest(request);
              },
              child: const Text(
                'REJECT',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await acceptRequest(request);
              },
              child: const Text('ACCEPT'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F8FA),

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

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : requests.isEmpty
              ? const _EmptyRequests()
              : RefreshIndicator(
                  onRefresh: loadRequests,

                  child: ListView(
                    padding:
                        const EdgeInsets.all(16),

                    children: [
                      const Text(
                        'New ride requests',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Requests for $currentDriverName will appear here.',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 20),

                      ...requests.map(
                        (request) => Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),

                          child:
                              _RideRequestCard(
                            request: request,
                            onView: () {
                              viewRequest(
                                request,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _RideRequestCard
    extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onView;

  const _RideRequestCard({
    required this.request,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final customerName =
        request['customerName'] ??
            'Customer';

    final driverName =
        request['driverName'] ??
            'Driver';

    final pickup =
        request['pickupAddress'] ??
            'Pickup location';

    final date =
        request['selectedDate'] ?? '';

    final time =
        request['selectedTime'] ?? '';

    final hours =
        request['hours'] ?? 1;

    final hourlyRate =
        request['hourlyRate'] ?? 0;

    final totalFare =
        request['totalFare'] ?? 0;

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: Colors.black12,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,

                backgroundColor:
                    Colors.black12,

                child: Text(
                  customerName
                          .toString()
                          .isNotEmpty
                      ? customerName
                          .toString()[0]
                          .toUpperCase()
                      : 'C',

                  style:
                      const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      customerName
                          .toString(),

                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Request for $driverName',

                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.orange
                      .withValues(
                    alpha: 0.12,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: const Text(
                  'NEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(),

          const SizedBox(height: 12),

          _RequestInfo(
            icon:
                Icons.location_on_outlined,
            text: pickup.toString(),
          ),

          const SizedBox(height: 10),

          _RequestInfo(
            icon:
                Icons.calendar_today_outlined,
            text:
                '${date.toString()} • ${time.toString()}',
          ),

          const SizedBox(height: 10),

          _RequestInfo(
            icon: Icons.access_time,
            text:
                '$hours ${hours == 1 ? 'hour' : 'hours'}',
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [
              const Text(
                'Estimated fare',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),

              Text(
                '₹$totalFare',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Align(
            alignment:
                Alignment.centerRight,

            child: Text(
              '₹$hourlyRate/hr',

              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 46,

            child: ElevatedButton(
              onPressed: onView,

              style:
                  ElevatedButton.styleFrom(
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),

              child: const Text(
                'VIEW REQUEST',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestInfo
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RequestInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Icon(
          icon,
          size: 18,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,
            style:
                const TextStyle(
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow
    extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        SizedBox(
          width: 100,

          child: Text(
            label,
            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,

            style: TextStyle(
              fontSize: 13,
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyRequests
    extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.inbox_outlined,
              size: 55,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'No ride requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'New customer requests will appear here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
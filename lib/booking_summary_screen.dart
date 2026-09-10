import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';

class BookingSummaryScreen extends StatelessWidget {
  final LatLng pickupLocation;
  final String pickupAddress;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final int hours;
  final int hourlyRate;

  const BookingSummaryScreen({
    super.key,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.selectedDate,
    required this.selectedTime,
    required this.hours,
    required this.hourlyRate,
  });

  @override
  Widget build(BuildContext context) {
    final int totalFare = hourlyRate * hours;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Review Booking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please check your booking details before confirming.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 28),

            _SummaryCard(
              icon: Icons.location_on_outlined,
              title: 'Pickup location',
              value: pickupAddress,
            ),

            const SizedBox(height: 14),

            _SummaryCard(
              icon: Icons.calendar_today_outlined,
              title: 'Date',
              value:
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            ),

            const SizedBox(height: 14),

            _SummaryCard(
              icon: Icons.access_time,
              title: 'Time',
              value: selectedTime.format(context),
            ),

            const SizedBox(height: 14),

            _SummaryCard(
              icon: Icons.timer_outlined,
              title: 'Duration',
              value: '$hours ${hours == 1 ? 'hour' : 'hours'}',
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total fare',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹$totalFare',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹$hourlyRate per hour × $hours '
                    '${hours == 1 ? 'hour' : 'hours'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Booking details confirmed!',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'CONFIRM BOOKING',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
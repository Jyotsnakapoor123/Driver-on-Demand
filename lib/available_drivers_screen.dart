import 'package:flutter/material.dart';

class AvailableDriversScreen extends StatelessWidget {
  final String pickupAddress;
  final int hours;

  const AvailableDriversScreen({
    super.key,
    required this.pickupAddress,
    required this.hours,
  });

  final List<Map<String, dynamic>> drivers = const [
    {
      'name': 'Rahul Sharma',
      'rating': 4.8,
      'reviews': 124,
      'distance': 1.2,
      'rate': 300,
      'verified': true,
      'available': true,
    },
    {
      'name': 'Amit Kumar',
      'rating': 4.6,
      'reviews': 89,
      'distance': 2.4,
      'rate': 250,
      'verified': true,
      'available': true,
    },
    {
      'name': 'Rohit Singh',
      'rating': 4.9,
      'reviews': 156,
      'distance': 3.1,
      'rate': 350,
      'verified': true,
      'available': true,
    },
    {
      'name': 'Vikas Mehta',
      'rating': 4.5,
      'reviews': 61,
      'distance': 4.7,
      'rate': 280,
      'verified': true,
      'available': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final availableDrivers = drivers
        .where(
          (driver) =>
              driver['verified'] == true &&
              driver['available'] == true,
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Available Drivers',
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
              'Drivers near you',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Verified drivers available for your ride.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pickup location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pickupAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              '${availableDrivers.length} drivers available',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...availableDrivers.map(
              (driver) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _DriverCard(
                  name: driver['name'] as String,
                  rating: driver['rating'] as double,
                  reviews: driver['reviews'] as int,
                  distance: driver['distance'] as double,
                  rate: driver['rate'] as int,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only verified and currently available drivers are shown.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final String name;
  final double rating;
  final int reviews;
  final double distance;
  final int rate;

  const _DriverCard({
    required this.name,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.black12,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          size: 17,
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 17,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$rating',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($reviews reviews)',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.location_on_outlined,
                  label: '${distance.toStringAsFixed(1)} km away',
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.access_time,
                  label: 'Available now',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hourly charge',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              Text(
                '₹$rate/hr',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

class AvailableDriversScreen extends StatefulWidget {
  final String pickupAddress;
  final int hours;

  const AvailableDriversScreen({
    super.key,
    required this.pickupAddress,
    required this.hours,
  });

  @override
  State<AvailableDriversScreen> createState() =>
      _AvailableDriversScreenState();
}

class _AvailableDriversScreenState extends State<AvailableDriversScreen> {
  String sortBy = 'Recommended';

  double? minimumRating;
  int? maximumRate;
  double? maximumDistance;

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

  List<Map<String, dynamic>> getFilteredDrivers() {
    final filtered = drivers.where((driver) {
      final isAvailable = driver['available'] == true;
      final isVerified = driver['verified'] == true;

      if (!isAvailable || !isVerified) {
        return false;
      }

      if (minimumRating != null &&
          (driver['rating'] as double) < minimumRating!) {
        return false;
      }

      if (maximumRate != null &&
          (driver['rate'] as int) > maximumRate!) {
        return false;
      }

      if (maximumDistance != null &&
          (driver['distance'] as double) > maximumDistance!) {
        return false;
      }

      return true;
    }).toList();

    switch (sortBy) {
      case 'Highest Rated':
        filtered.sort(
          (a, b) =>
              (b['rating'] as double).compareTo(a['rating'] as double),
        );
        break;

      case 'Nearest':
        filtered.sort(
          (a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double),
        );
        break;

      case 'Lowest Charge':
        filtered.sort(
          (a, b) => (a['rate'] as int).compareTo(b['rate'] as int),
        );
        break;

      case 'Recommended':
      default:
        break;
    }

    return filtered;
  }

  void openSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        final options = [
          'Recommended',
          'Highest Rated',
          'Nearest',
          'Lowest Charge',
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort drivers by',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map(
                  (option) => RadioListTile<String>(
                    value: option,
                    groupValue: sortBy,
                    title: Text(option),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        sortBy = value;
                      });

                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void openFilterSheet() {
    double? tempRating = minimumRating;
    int? tempMaximumRate = maximumRate;
    double? tempMaximumDistance = maximumDistance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter drivers',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                tempRating = null;
                                tempMaximumRate = null;
                                tempMaximumDistance = null;
                              });
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Minimum rating',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Any'),
                            selected: tempRating == null,
                            onSelected: (_) {
                              setSheetState(() {
                                tempRating = null;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('4.0+'),
                            selected: tempRating == 4.0,
                            onSelected: (_) {
                              setSheetState(() {
                                tempRating = 4.0;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('4.5+'),
                            selected: tempRating == 4.5,
                            onSelected: (_) {
                              setSheetState(() {
                                tempRating = 4.5;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Maximum hourly charge',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Any'),
                            selected: tempMaximumRate == null,
                            onSelected: (_) {
                              setSheetState(() {
                                tempMaximumRate = null;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('₹250/hr'),
                            selected: tempMaximumRate == 250,
                            onSelected: (_) {
                              setSheetState(() {
                                tempMaximumRate = 250;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('₹300/hr'),
                            selected: tempMaximumRate == 300,
                            onSelected: (_) {
                              setSheetState(() {
                                tempMaximumRate = 300;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('₹350/hr'),
                            selected: tempMaximumRate == 350,
                            onSelected: (_) {
                              setSheetState(() {
                                tempMaximumRate = 350;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Maximum distance',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Any'),
                            selected: tempMaximumDistance == null,
                            onSelected: (_) {
                              setSheetState(() {
                                tempMaximumDistance = null;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('1 km'),
                            selected: tempMaximumDistance == 1,
                            onSelected: (_) {
                              setSheetState(() {
                                tempMaximumDistance = 1;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('2 km'),
                            selected: tempMaximumDistance == 2,
                            onSelected: (_) {
                              setSheetState(() {
                                tempMaximumDistance = 2;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('3 km'),
                            selected: tempMaximumDistance == 3,
                            onSelected: (_) {
                              setSheetState(() {
                                tempMaximumDistance = 3;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('5 km'),
                            selected: tempMaximumDistance == 5,
                            onSelected: (_) {
                              setSheetState(() {
                                tempMaximumDistance = 5;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              minimumRating = tempRating;
                              maximumRate = tempMaximumRate;
                              maximumDistance = tempMaximumDistance;
                            });

                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'APPLY FILTERS',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableDrivers = getFilteredDrivers();

    final hasFilters =
        minimumRating != null ||
        maximumRate != null ||
        maximumDistance != null;

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
                          widget.pickupAddress,
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

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: openSortSheet,
                    icon: const Icon(
                      Icons.swap_vert,
                      size: 19,
                    ),
                    label: Text(
                      sortBy == 'Recommended' ? 'Sort' : sortBy,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: openFilterSheet,
                    icon: const Icon(
                      Icons.tune,
                      size: 19,
                    ),
                    label: Text(
                      hasFilters ? 'Filters applied' : 'Filters',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${availableDrivers.length} drivers available',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (hasFilters)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        minimumRating = null;
                        maximumRate = null;
                        maximumDistance = null;
                      });
                    },
                    child: const Text('Clear filters'),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            if (availableDrivers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 42,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No drivers match your filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Try changing or clearing your filters.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            else
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
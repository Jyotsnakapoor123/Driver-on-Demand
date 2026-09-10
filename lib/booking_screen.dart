import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'map_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  LatLng? selectedLocation;
  String? selectedAddress;

  int hours = 1;
  int hourlyRate = 300;

  // ----------------------------------------------------------
  // DATE
  // ----------------------------------------------------------

  Future<void> selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 30),
      ),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // ----------------------------------------------------------
  // TIME
  // ----------------------------------------------------------

  Future<void> selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  // ----------------------------------------------------------
  // LOCATION
  // ----------------------------------------------------------

  Future<void> selectLocation() async {
    final MapLocationResult? result =
        await Navigator.push<MapLocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => const MapScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        selectedLocation = result.location;
        selectedAddress = result.address;
      });
    }
  }

  // ----------------------------------------------------------
  // FIND DRIVER
  // ----------------------------------------------------------

  void findDriver() {
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select your pickup location first.',
          ),
        ),
      );
      return;
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select the date.',
          ),
        ),
      );
      return;
    }

    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select the time.',
          ),
        ),
      );
      return;
    }

    print('Finding a driver...');
    print('Location: $selectedAddress');
    print('Latitude: ${selectedLocation!.latitude}');
    print('Longitude: ${selectedLocation!.longitude}');
    print('Date: $selectedDate');
    print('Time: $selectedTime');
    print('Duration: $hours hours');
    print('Estimated fare: ₹${hourlyRate * hours}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Searching for available drivers...',
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Book a Driver',
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
              'Book a verified driver',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'For your own car, whenever you need.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 28),

            // ------------------------------------------------
            // PICKUP LOCATION
            // ------------------------------------------------

            const Text(
              'Pickup location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            InkWell(
              onTap: selectLocation,
              borderRadius: BorderRadius.circular(14),

              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selectedLocation == null
                        ? Colors.transparent
                        : Colors.black12,
                  ),
                ),

                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: selectedLocation == null
                          ? Colors.grey
                          : Colors.red,
                      size: 25,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedLocation == null
                                ? 'Choose pickup location'
                                : 'Pickup location',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  selectedLocation == null
                                      ? Colors.grey
                                      : Colors.grey,
                            ),
                          ),

                          if (selectedAddress != null) ...[
                            const SizedBox(height: 4),

                            Text(
                              selectedAddress!,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.chevron_right,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ------------------------------------------------
            // DATE & TIME
            // ------------------------------------------------

            const Text(
              'When do you need the driver?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _BookingOption(
                    icon: Icons.calendar_today_outlined,
                    title: selectedDate == null
                        ? 'Select date'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    onTap: selectDate,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _BookingOption(
                    icon: Icons.access_time,
                    title: selectedTime == null
                        ? 'Select time'
                        : selectedTime!.format(context),
                    onTap: selectTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ------------------------------------------------
            // DURATION
            // ------------------------------------------------

            const Text(
              'Duration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    'Driver needed for',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),

                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (hours > 1) {
                            setState(() {
                              hours--;
                            });
                          }
                        },
                        icon: const Icon(Icons.remove),
                      ),

                      Text(
                        '$hours ${hours == 1 ? 'hour' : 'hours'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          setState(() {
                            hours++;
                          });
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ------------------------------------------------
            // FARE
            // ------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Estimated fare',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '₹${hourlyRate * hours}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '₹$hourlyRate per hour',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ------------------------------------------------
            // TRUST
            // ------------------------------------------------

            const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                ),

                SizedBox(width: 8),

                Text(
                  'Verified & background-checked drivers',
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------
            // FIND DRIVER
            // ------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton(
                onPressed: findDriver,

                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),

                child: const Text(
                  'FIND A DRIVER',
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

// ============================================================
// BOOKING OPTION
// ============================================================

class _BookingOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _BookingOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(14),

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Icon(
              icon,
              size: 22,
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'driver_auth_storage.dart';
import 'driver_availability_storage.dart';
import 'driver_location_storage.dart';
import 'driver_profile_screen.dart';
import 'driver_verification_screen.dart';
import 'driver_ride_requests_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const DriverHomeScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<DriverHomeScreen> createState() =>
      _DriverHomeScreenState();
}

class _DriverHomeScreenState
    extends State<DriverHomeScreen> {
  bool isAvailable = false;
  bool isLoading = true;

  bool isGettingLocation = false;

  double? driverLatitude;
  double? driverLongitude;

  @override
  void initState() {
    super.initState();

    _loadAvailability();
    _loadSavedLocation();
  }

  // ============================================================
  // AVAILABILITY
  // ============================================================

  Future<void> _loadAvailability() async {
    final available =
        await DriverAvailabilityStorage.isAvailable();

    if (!mounted) return;

    setState(() {
      isAvailable = available;
      isLoading = false;
    });
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() {
      isAvailable = value;
    });

    await DriverAvailabilityStorage.setAvailable(value);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'You are now available for rides.'
              : 'You are now offline.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // SAVED DRIVER LOCATION
  // ============================================================

  Future<void> _loadSavedLocation() async {
    final location =
        await DriverLocationStorage.getLocation();

    if (!mounted || location == null) return;

    setState(() {
      driverLatitude = location['latitude'];
      driverLongitude = location['longitude'];
    });
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    if (isGettingLocation) return;

    setState(() {
      isGettingLocation = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          isGettingLocation = false;
        });

        _showLocationMessage(
          'Please turn on your device location service.',
        );

        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          isGettingLocation = false;
        });

        _showLocationMessage(
          'Location permission was denied.',
        );

        return;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          isGettingLocation = false;
        });

        _showLocationMessage(
          'Location permission is permanently denied. Please enable it from app settings.',
        );

        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await DriverLocationStorage.saveLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      setState(() {
        driverLatitude = position.latitude;
        driverLongitude = position.longitude;
        isGettingLocation = false;
      });

      _showLocationMessage(
        'Current location updated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isGettingLocation = false;
      });

      _showLocationMessage(
        'Unable to get your current location.',
      );
    }
  }

  void _showLocationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('LOGOUT'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await DriverAuthStorage.logout();

    if (!context.mounted) return;

    widget.onLogout();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const DriverProfileScreen(),
      ),
    );
  }

  void _openVerification(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const DriverVerificationScreen(),
      ),
    );
  }

  void _openRideRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const DriverRideRequestsScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        driverLatitude != null &&
        driverLongitude != null;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Driver Portal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                _openProfile(context),
            icon: const Icon(
              Icons.person_outline,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics:
            const BouncingScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(
          16,
          30,
          16,
          24,
        ),

        child: Column(
          children: [
            // ====================================================
            // DRIVER ICON
            // ====================================================

            Container(
              width: 100,
              height: 100,
              decoration:
                  const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.drive_eta_outlined,
                size: 52,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Welcome, Driver!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Manage your driver account from here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            // ====================================================
            // DRIVER AVAILABILITY
            // ====================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),

              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration:
                            BoxDecoration(
                          color: isAvailable
                              ? Colors.green
                                  .shade100
                              : Colors.grey
                                  .shade200,
                          shape:
                              BoxShape.circle,
                        ),
                        child: Icon(
                          isAvailable
                              ? Icons
                                  .check_circle_outline
                              : Icons
                                  .power_settings_new,
                          color: isAvailable
                              ? Colors.green
                                  .shade700
                              : Colors.grey
                                  .shade700,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              'Driver Availability',
                              style:
                                  TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Choose whether you want to receive ride requests.',
                              style:
                                  TextStyle(
                                fontSize: 13,
                                color:
                                    Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isLoading)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Switch(
                          value: isAvailable,
                          onChanged:
                              _toggleAvailability,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),

                    decoration:
                        BoxDecoration(
                      color: isAvailable
                          ? Colors.green
                              .shade50
                          : Colors.grey
                              .shade100,
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),

                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: isAvailable
                              ? Colors.green
                                  .shade700
                              : Colors.grey
                                  .shade600,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            isAvailable
                                ? 'You are AVAILABLE for rides'
                                : 'You are currently OFFLINE',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w600,
                              color: isAvailable
                                  ? Colors.green
                                      .shade700
                                  : Colors.grey
                                      .shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ====================================================
            // DRIVER CURRENT LOCATION
            // ====================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration:
                            BoxDecoration(
                          color: hasLocation
                              ? Colors.green
                                  .shade100
                              : Colors.blue
                                  .shade100,
                          shape:
                              BoxShape.circle,
                        ),
                        child: Icon(
                          hasLocation
                              ? Icons
                                  .location_on
                              : Icons
                                  .my_location,
                          color: hasLocation
                              ? Colors.green
                                  .shade700
                              : Colors.blue
                                  .shade700,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              'Current Location',
                              style:
                                  TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Update your current GPS location.',
                              style:
                                  TextStyle(
                                fontSize: 13,
                                color:
                                    Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(14),

                    decoration:
                        BoxDecoration(
                      color: hasLocation
                          ? Colors.green
                              .shade50
                          : Colors.grey
                              .shade100,
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),

                    child: hasLocation
                        ? Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons
                                        .check_circle,
                                    size: 18,
                                    color: Colors
                                        .green
                                        .shade700,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    'Location detected',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                      color: Colors
                                          .green
                                          .shade700,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              Text(
                                'Latitude: ${driverLatitude!.toStringAsFixed(6)}',
                                style:
                                    const TextStyle(
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                'Longitude: ${driverLongitude!.toStringAsFixed(6)}',
                                style:
                                    const TextStyle(
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Location not detected yet.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 48,

                    child: ElevatedButton.icon(
                      onPressed:
                          isGettingLocation
                              ? null
                              : _getCurrentLocation,

                      icon: isGettingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .my_location,
                            ),

                      label: Text(
                        isGettingLocation
                            ? 'GETTING LOCATION...'
                            : hasLocation
                                ? 'UPDATE LOCATION'
                                : 'GET CURRENT LOCATION',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ====================================================
            // DRIVER PROFILE
            // ====================================================

            _HomeMenuCard(
              icon:
                  Icons.person_outline,
              title: 'Driver Profile',
              subtitle:
                  'View and edit your personal information.',
              onTap: () =>
                  _openProfile(context),
            ),

            const SizedBox(height: 14),

            // ====================================================
            // DRIVER VERIFICATION
            // ====================================================

            _HomeMenuCard(
              icon:
                  Icons.verified_user_outlined,
              title:
                  'Driver Verification',
              subtitle:
                  'Verify your identity and vehicle.',
              onTap: () =>
                  _openVerification(context),
            ),

            const SizedBox(height: 14),

            // ====================================================
            // RIDE REQUESTS
            // ====================================================

            _HomeMenuCard(
              icon:
                  Icons.notifications_none,
              title: 'Ride Requests',
              subtitle:
                  'View incoming requests from customers.',
              onTap: () =>
                  _openRideRequests(context),
            ),

            const SizedBox(height: 24),

            // ====================================================
            // LOGOUT
            // ====================================================

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () =>
                    _logout(context),
                child: const Text(
                  'LOGOUT',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// REUSABLE HOME MENU CARD
// ================================================================

class _HomeMenuCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(16),

      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),

        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(20),

          child: Row(
            children: [
              Icon(
                icon,
                size: 30,
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
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
    );
  }
}
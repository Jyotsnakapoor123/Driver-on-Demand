import 'package:flutter/material.dart';

import 'driver_auth_storage.dart';
import 'driver_availability_storage.dart';
import 'driver_profile_screen.dart';
import 'driver_verification_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const DriverHomeScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool isAvailable = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final available =
        await DriverAvailabilityStorage.isAvailable();

    if (!mounted) {
      return;
    }

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

    if (!mounted) {
      return;
    }

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
                Navigator.pop(dialogContext, false);
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('LOGOUT'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await DriverAuthStorage.logout();

    if (!context.mounted) {
      return;
    }

    widget.onLogout();
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DriverProfileScreen(),
      ),
    );
  }

  void _openVerification(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DriverVerificationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),

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
            onPressed: () => _openProfile(context),
            icon: const Icon(
              Icons.person_outline,
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 30),

            // Driver Icon
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.drive_eta_outlined,
                size: 48,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Welcome, Driver!',
              style: TextStyle(
                fontSize: 26,
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

            // =========================
            // DRIVER AVAILABILITY
            // =========================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),

                        child: Icon(
                          isAvailable
                              ? Icons.check_circle_outline
                              : Icons.power_settings_new,
                          color: isAvailable
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Driver Availability',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              'Choose whether you want to receive ride requests.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isLoading)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Switch(
                          value: isAvailable,
                          onChanged: _toggleAvailability,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),

                    decoration: BoxDecoration(
                      color: isAvailable
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Row(
                      children: [
                        Icon(
                          isAvailable
                              ? Icons.circle
                              : Icons.circle_outlined,
                          size: 12,
                          color: isAvailable
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),

                        const SizedBox(width: 10),

                        Text(
                          isAvailable
                              ? 'You are AVAILABLE for rides'
                              : 'You are currently OFFLINE',

                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isAvailable
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // =========================
            // DRIVER PROFILE
            // =========================

            GestureDetector(
              onTap: () => _openProfile(context),

              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: const Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 30,
                    ),

                    SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 6),

                          Text(
                            'View and edit your personal information.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // =========================
            // DRIVER VERIFICATION
            // =========================

            GestureDetector(
              onTap: () => _openVerification(context),

              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 30,
                    ),

                    SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver Verification',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 6),

                          Text(
                            'Verify your identity and vehicle.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // =========================
            // LOGOUT
            // =========================

            SizedBox(
              width: double.infinity,
              height: 52,

              child: OutlinedButton(
                onPressed: () => _logout(context),

                child: const Text(
                  'LOGOUT',
                  style: TextStyle(
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
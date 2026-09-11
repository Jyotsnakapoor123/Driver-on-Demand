import 'package:flutter/material.dart';

import 'auth_screen.dart';
import 'auth_storage.dart';
import 'booking_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';

import 'driver_auth_screen.dart';
import 'driver_auth_storage.dart';
import 'driver_home_screen.dart';

void main() {
  runApp(const DriverOnDemandApp());
}

class DriverOnDemandApp extends StatelessWidget {
  const DriverOnDemandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Driver On Demand',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? customerLoggedIn;
  bool? driverLoggedIn;

  bool isDriverMode = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final customerStatus = await AuthStorage.isLoggedIn();
    final driverStatus = await DriverAuthStorage.isLoggedIn();

    if (!mounted) {
      return;
    }

    setState(() {
      customerLoggedIn = customerStatus;
      driverLoggedIn = driverStatus;
    });
  }

  void openDriverLogin() {
    setState(() {
      isDriverMode = true;
    });
  }

  void openCustomerLogin() {
    setState(() {
      isDriverMode = false;
    });
  }

  void handleCustomerLogin() {
    setState(() {
      customerLoggedIn = true;
      isDriverMode = false;
    });
  }

  void handleDriverLogin() {
    setState(() {
      driverLoggedIn = true;
      isDriverMode = true;
    });
  }

  void handleCustomerLogout() {
    setState(() {
      customerLoggedIn = false;
      isDriverMode = false;
    });
  }

  void handleDriverLogout() {
    setState(() {
      driverLoggedIn = false;
      isDriverMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initial loading
    if (customerLoggedIn == null || driverLoggedIn == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Driver is logged in
    if (isDriverMode && driverLoggedIn!) {
      return DriverHomeScreen(
        onLogout: handleDriverLogout,
      );
    }

    // Driver login/signup screen
    if (isDriverMode && !driverLoggedIn!) {
      return DriverAuthScreen(
        onAuthSuccess: handleDriverLogin,
        onBackToCustomer: openCustomerLogin,
      );
    }

    // Customer is logged in
    if (customerLoggedIn!) {
      return HomeScreen(
        onLogout: handleCustomerLogout,
      );
    }

    // Customer login/signup
    return AuthScreen(
      onAuthSuccess: handleCustomerLogin,
      onDriverLogin: openDriverLogin,
    );
  }
}

class HomeScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver On Demand'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    onLogout: onLogout,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your car. Your driver.',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Book a verified driver by the hour.',
              style: TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookingScreen(),
                  ),
                );
              },
              child: const Text('BOOK A DRIVER'),
            ),

            const SizedBox(height: 20),

            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyBookingsScreen(),
                  ),
                );
              },
              child: const Text('MY BOOKINGS'),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import 'driver_verification_storage.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  State<DriverVerificationScreen> createState() =>
      _DriverVerificationScreenState();
}

class _DriverVerificationScreenState
    extends State<DriverVerificationScreen> {
  String verificationStatus =
      DriverVerificationStorage.statusNotSubmitted;

  String? licenseNumber;
  String? vehicleNumber;

  @override
  void initState() {
    super.initState();
    _loadVerification();
  }

  Future<void> _loadVerification() async {
    final status =
        await DriverVerificationStorage.getStatus();

    final license =
        await DriverVerificationStorage.getLicenseNumber();

    final vehicle =
        await DriverVerificationStorage.getVehicleNumber();

    if (!mounted) {
      return;
    }

    setState(() {
      verificationStatus = status;
      licenseNumber = license;
      vehicleNumber = vehicle;
    });
  }

  void _openVerificationForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverVerificationFormScreen(
          licenseNumber: licenseNumber ?? '',
          vehicleNumber: vehicleNumber ?? '',
        ),
      ),
    ).then((_) {
      _loadVerification();
    });
  }

  Color _statusColor() {
    switch (verificationStatus) {
      case DriverVerificationStorage.statusVerified:
        return Colors.green.shade700;

      case DriverVerificationStorage.statusRejected:
        return Colors.red.shade700;

      case DriverVerificationStorage.statusPending:
        return Colors.orange.shade700;

      default:
        return Colors.grey.shade700;
    }
  }

  Color _statusBackground() {
    switch (verificationStatus) {
      case DriverVerificationStorage.statusVerified:
        return Colors.green.shade50;

      case DriverVerificationStorage.statusRejected:
        return Colors.red.shade50;

      case DriverVerificationStorage.statusPending:
        return Colors.orange.shade50;

      default:
        return Colors.grey.shade100;
    }
  }

  String _statusTitle() {
    switch (verificationStatus) {
      case DriverVerificationStorage.statusVerified:
        return 'Verified';

      case DriverVerificationStorage.statusRejected:
        return 'Verification Rejected';

      case DriverVerificationStorage.statusPending:
        return 'Verification Pending';

      default:
        return 'Not Verified';
    }
  }

  String _statusDescription() {
    switch (verificationStatus) {
      case DriverVerificationStorage.statusVerified:
        return 'Your driver account has been verified.';

      case DriverVerificationStorage.statusRejected:
        return 'Your verification needs to be reviewed again.';

      case DriverVerificationStorage.statusPending:
        return 'Your documents have been submitted and are awaiting review.';

      default:
        return 'Complete your verification to start accepting rides.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSubmitted =
        verificationStatus !=
            DriverVerificationStorage.statusNotSubmitted;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Driver Verification',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                size: 48,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Verify Your Driver Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Verification helps us build a trusted driver network.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 28),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _statusBackground(),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    verificationStatus ==
                            DriverVerificationStorage.statusVerified
                        ? Icons.verified
                        : verificationStatus ==
                                DriverVerificationStorage
                                    .statusPending
                            ? Icons.pending_outlined
                            : Icons.info_outline,
                    color: _statusColor(),
                    size: 30,
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusTitle(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _statusColor(),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _statusDescription(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (hasSubmitted)
              _DocumentCard(
                title: 'Driving Licence',
                value: licenseNumber ?? 'Not available',
                icon: Icons.credit_card_outlined,
              ),

            if (hasSubmitted)
              const SizedBox(height: 12),

            if (hasSubmitted)
              _DocumentCard(
                title: 'Vehicle Number',
                value: vehicleNumber ?? 'Not available',
                icon: Icons.directions_car_outlined,
              ),

            if (hasSubmitted)
              const SizedBox(height: 20),

            if (!hasSubmitted ||
                verificationStatus ==
                    DriverVerificationStorage.statusRejected)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _openVerificationForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    hasSubmitted
                        ? 'SUBMIT AGAIN'
                        : 'START VERIFICATION',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            const Text(
              'In the production version, submitted documents will be reviewed by the verification team.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverVerificationFormScreen extends StatefulWidget {
  final String licenseNumber;
  final String vehicleNumber;

  const DriverVerificationFormScreen({
    super.key,
    required this.licenseNumber,
    required this.vehicleNumber,
  });

  @override
  State<DriverVerificationFormScreen> createState() =>
      _DriverVerificationFormScreenState();
}

class _DriverVerificationFormScreenState
    extends State<DriverVerificationFormScreen> {
  late final TextEditingController _licenseController;
  late final TextEditingController _vehicleController;

  @override
  void initState() {
    super.initState();

    _licenseController = TextEditingController(
      text: widget.licenseNumber,
    );

    _vehicleController = TextEditingController(
      text: widget.vehicleNumber,
    );
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final license = _licenseController.text.trim().toUpperCase();
    final vehicle = _vehicleController.text.trim().toUpperCase();

    if (license.isEmpty) {
      _showError('Please enter your driving licence number.');
      return;
    }

    if (license.length < 5) {
      _showError('Please enter a valid driving licence number.');
      return;
    }

    if (vehicle.isEmpty) {
      _showError('Please enter your vehicle number.');
      return;
    }

    if (vehicle.length < 5) {
      _showError('Please enter a valid vehicle number.');
      return;
    }

    await DriverVerificationStorage.submitVerification(
      licenseNumber: license,
      vehicleNumber: vehicle,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Verification submitted successfully.',
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
          'Submit Verification',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            _InputField(
              controller: _licenseController,
              label: 'Driving Licence Number',
              hint: 'e.g. DL1420110012345',
              icon: Icons.credit_card_outlined,
            ),

            const SizedBox(height: 16),

            _InputField(
              controller: _vehicleController,
              label: 'Vehicle Number',
              hint: 'e.g. HR06AB1234',
              icon: Icons.directions_car_outlined,
            ),

            const SizedBox(height: 28),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For this MVP, verification details are stored locally. Real document upload and admin verification will be connected when the backend is added.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'SUBMIT FOR VERIFICATION',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DocumentCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
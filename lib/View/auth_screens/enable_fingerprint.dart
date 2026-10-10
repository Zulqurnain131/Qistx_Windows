import 'package:flutter/material.dart';
import 'package:qistx_app/Controllers/biometric_service.dart';

class EnableFingerprint extends StatefulWidget {
  const EnableFingerprint({super.key});

  @override
  State<EnableFingerprint> createState() => _EnableFingerprintState();
}

class _EnableFingerprintState extends State<EnableFingerprint> {
  final BiometricService _biometricService = BiometricService();

  Future<void> _handleBiometricAuth() async {
    final supported = await _biometricService.isDeviceSupported();

    if (!supported) {
      _showMessage('Biometric authentication is not supported on this device.');
      return;
    }

    final canCheck = await _biometricService.canCheckBiometrics();

    if (!canCheck) {
      _showMessage(
        'Please set up fingerprint or biometric authentication on your device first.',
      );
      return;
    }

    final authenticated = await _biometricService.authenticate(
      reason:
          'Please authenticate to enable biometric unlock for your QistX account.',
    );

    if (!mounted) return;

    if (authenticated) {
      debugPrint("Fingerprint authentication SUCCESS");

      await _biometricService.setBiometricEnabled(true);

      final enabled = await _biometricService.isBiometricEnabled();

      debugPrint("Biometric value after saving = $enabled");

      if (!mounted) return;

      if (enabled) {
        _showMessage('Biometric unlock enabled successfully.');
      } else {
        _showMessage('Biometric setting could not be saved.');
      }
    }
  }

  void _handleSkip() {
    // Skip logic goes here
  }
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Heading
              const Text(
                'Enable Fingerprint\nUnlock',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              const Text(
                'Use Fingerprint unlock for quick and safe access to your QistX account.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              // Fingerprint Icon in the center
              Center(
                child: Icon(
                  Icons.fingerprint,
                  size: 110,
                  color: Colors.orange.shade300,
                ),
              ),
              const Spacer(),
              // Skip Button
              OutlinedButton(
                onPressed: _handleSkip,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  side: const BorderSide(color: Colors.orange, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Enable Biometric Button
              ElevatedButton(
                onPressed: _handleBiometricAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enable Biometric',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

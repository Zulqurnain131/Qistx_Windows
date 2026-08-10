import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qistx_app/Controllers/biometric_service.dart';
import 'package:qistx_app/View/users_screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PinVerificationScreen extends StatefulWidget {
  const PinVerificationScreen({super.key});

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final BiometricService _biometricService = BiometricService();
  String userEmail = "";
  final SupabaseClient _supabase = Supabase.instance.client;
  // Pin Verification controllers & focus nodes
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());
  @override
  void initState() {
    super.initState();

    userEmail = _supabase.auth.currentUser?.email ?? "";
    _saveCurrentScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricLogin();
    });
  }

  Future<void> _tryBiometricLogin() async {
    debugPrint("================================");
    debugPrint("BIOMETRIC LOGIN STARTED");
    debugPrint("================================");

    final biometricEnabled = await _biometricService.isBiometricEnabled();

    debugPrint("biometric_enabled = $biometricEnabled");

    if (!biometricEnabled) {
      debugPrint("Biometric is NOT enabled.");
      return;
    }

    if (!mounted) {
      debugPrint("Widget is not mounted.");
      return;
    }

    final supported = await _biometricService.isDeviceSupported();

    debugPrint("Device supported = $supported");

    if (!supported) {
      debugPrint("Device does not support biometric.");
      return;
    }

    final canCheck = await _biometricService.canCheckBiometrics();

    debugPrint("Can check biometrics = $canCheck");

    if (!canCheck) {
      debugPrint("Cannot check biometrics.");
      return;
    }

    debugPrint("Opening biometric popup...");
    final authenticated = await _biometricService.authenticate(
      reason:
          'Please authenticate to enable biometric unlock for your QistX account.',
    );

    debugPrint("Authentication result = $authenticated");

    if (!mounted) return;

    if (authenticated) {
      debugPrint("BIOMETRIC SUCCESS");

      final prefs = await SharedPreferences.getInstance();

      await prefs.remove("last_screen");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      debugPrint("BIOMETRIC CANCELLED OR FAILED");

      // Kuch nahi karna.
      // User isi PIN screen par rahega.
    }
  }

  Future<void> _saveCurrentScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("last_screen", "pin_verification");
  }

  @override
  void dispose() {
    // Memory leaks se bachne ke liye controllers ko dispose karein
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  ///////////////////////////// Verify Pin in Supabase ////////
  Future<bool> verifyPin(String pin) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      // User ka saved hash fetch karo
      final response = await _supabase
          .from('app_users')
          .select('pin_hash')
          .eq('id', user.id)
          .single();

      final savedHash = response['pin_hash'];

      // Entered PIN ko hash karo
      final enteredHash = sha256.convert(utf8.encode(pin)).toString();

      return enteredHash == savedHash;
    } catch (e) {
      debugPrint("Verify PIN Error: $e");
      return false;
    }
  }
  ////////////////////////////// Pin Verify ////

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final bool isDesktop = screenWidth > 800;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: isMobile ? 50 : 60,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isShortScreen = constraints.maxHeight < 620;

            return Stack(
              children: [
                // Layer 1: Bottom Right Wave Image (desktop only — hidden on mobile/tablet)
                if (isDesktop && constraints.maxWidth > 320)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: RepaintBoundary(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.7,
                          child: Image.asset(
                            "assets/images/auth_confirmation_pin.png", // Wave asset
                            width: screenWidth * 0.20,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Layer 2: Top Left Brand Logo (desktop only — hidden on mobile/tablet)
                if (isDesktop && !isShortScreen && constraints.maxWidth > 350)
                  Positioned(
                    top: 20,
                    left: 40,
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: Image.asset(
                          "assets/Icons/Qist_Logo_trans.png", // Logo path
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                // Layer 3: Scrollable Center Content (Strictly Overflow Protected)
                Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24.0 : 40.0,
                        vertical: 20.0,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment
                              .center, // Centered alignments as per image_92e569
                          children: [
                            // Inline Logo for extreme small screen heights
                            // (desktop only — mobile/tablet never shows the QistX icon)
                            if (isDesktop &&
                                (isShortScreen ||
                                    constraints.maxWidth <= 350)) ...[
                              SizedBox(
                                width: 90,
                                height: 45,
                                child: Image.asset(
                                  "assets/Icons/Qist_Logo_trans.png",
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Welcome Header
                            Text(
                              "Welcome back!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 26 : (isDesktop ? 34 : 30),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Subtitle Instruction
                            Text(
                              "Enter your PIN",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            SizedBox(height: isMobile ? 24 : 32),

                            // PIN Code Row
                            RepaintBoundary(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  4,
                                  (index) => _buildPinField(
                                    index: index,
                                    isMobile: isMobile,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: isMobile ? 28 : 36),

                            // Forget your PIN Link (With orange highlighted PIN)
                            GestureDetector(
                              onTap: () {
                                // Forget password/pin logic here
                              },
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                  children: const [
                                    TextSpan(text: "Forget your "),
                                    TextSpan(
                                      text: "PIN",
                                      style: TextStyle(
                                        color: Color(
                                          0xFFFF5F00,
                                        ), // Brand Orange
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: isMobile ? 40 : 55),

                            // Face Scan / Biometric Activation Icon (Perfect representation of image_92e569)
                            IconButton(
                              onPressed: () {
                                _tryBiometricLogin();
                                // Face ID / Biometric fingerprint integration trigger
                              },
                              padding: EdgeInsets.zero,
                              iconSize: isMobile ? 64 : 76,
                              icon: Container(
                                height: isMobile ? 64 : 76,
                                width: isMobile ? 64 : 76,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFF5F00,
                                    ).withOpacity(0.15),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  color: const Color(0xFFFFF5EE),
                                ),
                                child: const Icon(
                                  Icons
                                      .fingerprint, // Best matches the visual outline icon
                                  size: 38,
                                  color: Color(0xFFFF5F00),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Row ke andar elements ki safety aur backspace redirection logic
  Widget _buildPinField({required int index, required bool isMobile}) {
    return Flexible(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? 54 : 64,
          maxHeight: isMobile ? 54 : 64,
        ),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: KeyboardListener(
            focusNode: FocusNode(skipTraversal: true),
            onKeyEvent: (KeyEvent event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace) {
                if (_pinControllers[index].text.isEmpty && index > 0) {
                  _pinFocusNodes[index - 1].requestFocus();
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 5.0,
              ), // Row components safe padding
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF1).withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: TextFormField(
                  controller: _pinControllers[index],
                  focusNode: _pinFocusNodes[index],
                  textAlign: TextAlign.center,
                  obscureText: true,
                  obscuringCharacter: "●",
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(1),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: "",
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      if (index < 3) {
                        _pinFocusNodes[index + 1].requestFocus();
                      } else {
                        _pinFocusNodes[index].unfocus();
                        _verifyPin(); // Complete PIN validation trigger
                      }
                    } else {
                      if (index > 0) {
                        _pinFocusNodes[index - 1].requestFocus();
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Pin verification confirmation action call
  Future<void> _verifyPin() async {
    String pin = _pinControllers.map((e) => e.text).join();

    if (pin.length != 4) return;

    bool success = await verifyPin(pin);

    if (!mounted) return;

    if (success) {
      debugPrint("PIN Verified Successfully");
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("current_screen");

      // Home Screen par bhej dein
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid PIN")));

      // PIN fields clear
      for (var controller in _pinControllers) {
        controller.clear();
      }

      // First field focus
      _pinFocusNodes.first.requestFocus();
    }
  }
}

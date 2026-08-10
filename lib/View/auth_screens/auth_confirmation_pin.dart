import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qistx_app/View/auth_screens/auth_create_pin.dart';
import 'package:qistx_app/View/auth_screens/pin_verification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthConfirmationPin extends StatefulWidget {
  final String email;
  const AuthConfirmationPin({super.key, required this.email});

  @override
  State<AuthConfirmationPin> createState() => _AuthConfirmationPinState();
}

class _AuthConfirmationPinState extends State<AuthConfirmationPin> {
  int _resendCount = 1;
  // 1. Explicitly 6 controllers aur focus nodes ensure karein
  final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _timer;

  int _remainingSeconds = 60;
  bool _canResend = false;
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  @override
  void initState() {
    super.initState();
    _saveCurrentScreen();
    // _startTimer();
    _restoreTimer();
  }

  //////////////////// Restore Timer ////
  Future<void> _saveTimer() async {
    final prefs = await SharedPreferences.getInstance();

    final expiry = DateTime.now()
        .add(Duration(seconds: _remainingSeconds))
        .millisecondsSinceEpoch;

    await prefs.setInt("otp_expiry", expiry);
  }

  Future<void> _restoreTimer() async {
    final prefs = await SharedPreferences.getInstance();

    final expiry = prefs.getInt("otp_expiry");

    if (expiry == null) {
      await _saveTimer();
      _startTimer();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = ((expiry - now) / 1000).ceil();

    if (remaining <= 0) {
      setState(() {
        _remainingSeconds = 0;
        _canResend = true;
      });
    } else {
      setState(() {
        _remainingSeconds = remaining;
        _canResend = false;
      });

      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });

        SharedPreferences.getInstance().then((prefs) {
          prefs.remove("otp_expiry");
        });

        timer.cancel();
      }
    });
  }

  ////////////// Resend Otp Function ///////////////////////
  Future<void> _resendOtp() async {
    if (!_canResend) return;

    try {
      await _supabase.auth.signInWithOtp(email: widget.email);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("New OTP Sent")));
      // _resendCount++;

      setState(() {
        _remainingSeconds = ++_resendCount * 60; // <-- Reset nahi, ADD hoga
        _canResend = false;
      });
      await _saveTimer();
      _startTimer(); // Timer dobara start
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _saveCurrentScreen() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("last_screen", "otp");
    await prefs.setString("otp_email", widget.email);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  ////          OTP VERIFY ///
  Future<bool> verifyOtp({required String email, required String otp}) async {
    try {
      // OTP Verify
      print("Verify OTP EMAIL:$email");
      await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      final user = _supabase.auth.currentUser;
      print("User ID = ${user?.id}");

      if (user == null) {
        throw Exception("User not found.");
      }

      // Check if user already exists in app_users
      final response = await _supabase
          .from('app_users')
          .select()
          .eq('id', user.id);
      print("Response = $response");

      if (response.isEmpty) {
        print("Inserting user...");

        await _supabase.from('app_users').insert({
          "id": user.id,
          "username": null,
          "is_active": true,
          "profile_image": null,
          "pin_hash": null,
        });
        print("Insert Success");
      }

      return true;
    } on AuthException catch (e) {
      debugPrint("Auth Error: ${e.message}");
      print("Message: ${e.message}");
      print("Status: ${e.statusCode}");
      print("Code: ${e.code}");
      return false;
    } catch (e) {
      debugPrint("Error: $e");
      return false;
    }
  }

  ////////////////// if the user pin exist or not  ///////////////////
  Future<bool> hasPin() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return false;

    final response = await _supabase
        .from('app_users')
        .select('pin_hash')
        .eq('id', user.id)
        .single();

    return response['pin_hash'] != null;
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
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
        child: isDesktop
            ? _buildDesktopLayout(screenSize) // Desktop view unchanged rahega
            : _buildMobileLayout(
                screenSize,
              ), // Mobile view optimized for all devices
      ),
    );
  }

  // ---- Mobile Layout (Aligned to Top instead of Center) ----
  Widget _buildMobileLayout(Size screenSize) {
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final bool isExtremelyNarrow = screenWidth < 280;

    return Stack(
      children: [
        // Background Wave Asset (Mobile ke liye optimized)
        if (screenWidth > 320)
          // Content Aligned to Top with Scroll/Padding
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.07,
                vertical:
                    screenHeight * 0.04, // Top se thoda spacing dene ke liye
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment
                      .start, // Left aligned jaisa image mein hai
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Confirmation",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: isExtremelyNarrow ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Text(
                      "We sent a confirmation code to your email\n${widget.email}",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: isExtremelyNarrow ? 11 : 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    // 6 PIN Input Boxes Row
                    RepaintBoundary(
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.start, // Left aligned row
                        children: List.generate(
                          6,
                          (index) => Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 8.0,
                              ), // Boxes ke darmiyan gap
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 48,
                                  maxHeight: 48,
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1.0,
                                  child: _buildPinField(
                                    index,
                                    true,
                                    screenWidth,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.035),

                    // Resend Timer / Button
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        children: [
                          Text(
                            _canResend
                                ? "Didn't receive the code? "
                                : "Resend code in ",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          InkWell(
                            onTap: _canResend ? () => _resendOtp() : null,
                            child: Text(
                              _canResend
                                  ? "Resend"
                                  : "${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}",
                              style: TextStyle(
                                color: _canResend
                                    ? const Color(0xFFFF5F00)
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---- Desktop Layout (Aapka purana desktop code secure rakha hai) ----
  Widget _buildDesktopLayout(Size screenSize) {
    final double screenWidth = screenSize.width;

    return Stack(
      children: [
        Positioned(
          bottom: 0,
          right: 0,
          child: RepaintBoundary(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.7,
                child: Image.asset(
                  "assets/images/auth_confirmation_pin.png",
                  width: screenWidth * 0.20,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 40,
          child: RepaintBoundary(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Image.asset(
                "assets/Icons/Qist_Logo_trans.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 20.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Confirmation",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "We sent a confirmation code to your email\n${widget.email}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 44),
                    RepaintBoundary(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          6,
                          (index) => Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 58,
                                maxHeight: 58,
                              ),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: _buildPinField(
                                  index,
                                  false,
                                  screenWidth,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 44),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          _canResend
                              ? "Didn't receive the code? "
                              : "Resend code in ",
                        ),
                        InkWell(
                          onTap: _canResend ? () => _resendOtp() : null,
                          child: Text(
                            _canResend
                                ? "Resend"
                                : "${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: _canResend
                                  ? const Color(0xFFFF5F00)
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinField(int index, bool isMobile, double maxWidth) {
    double horizontalMargin = maxWidth < 340 ? 3.0 : 4.5;

    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          // Range check lagaya taake index out of bound na ho
          if (_controllers[index].text.isEmpty &&
              index > 0 &&
              index < _focusNodes.length) {
            _focusNodes[index - 1].requestFocus();
          }
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
        decoration: BoxDecoration(
          color: const Color(0xFFECEFF1).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
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
                // Yahan index < 5 hona chahiye kyunki total 6 elements hain (0 se 5 tak)
                if (index < 5) {
                  _focusNodes[index + 1].requestFocus();
                } else {
                  _focusNodes[index].unfocus();
                  _verifyCode(); // Code complete check call
                }
              } else {
                if (index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }
              }
            },
          ),
        ),
      ),
    );
  }

  // Purely dynamic logic for verifying 6 digits without any index crash
  Future<void> _verifyCode() async {
    String code = _controllers.map((e) => e.text).join();

    if (code.length != 6) return;

    debugPrint("OTP Code Entered: $code");

    bool success = await verifyOtp(email: widget.email, otp: code);

    if (!mounted) return;

    if (success) {
      final prefs = await SharedPreferences.getInstance();

      // OTP complete ho gayi
      await prefs.remove("otp_email");
      await prefs.remove("last_screen");
      final pinExists = await hasPin();

      if (!mounted) return;

      if (pinExists) {
        // Next screen save
        await prefs.setString("last_screen", "pin_verification");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PinVerificationScreen()),
        );
      } else {
        // Next screen save
        await prefs.setString("last_screen", "create_pin");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthCreatePin()),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid OTP")));

      for (var controller in _controllers) {
        controller.clear();
      }

      _focusNodes.first.requestFocus();
    }
  }
}

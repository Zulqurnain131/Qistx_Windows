import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qistx_app/View/profilecreation/create_account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthCreatePin extends StatefulWidget {
  const AuthCreatePin({super.key});

  @override
  State<AuthCreatePin> createState() => _AuthCreatePinState();
}

class _AuthCreatePinState extends State<AuthCreatePin> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // First Row: Enter your PIN controllers & focus nodes
  final List<TextEditingController> _enterControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _enterFocusNodes = List.generate(4, (_) => FocusNode());

  // Second Row: Confirm your PIN controllers & focus nodes
  final List<TextEditingController> _confirmControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _confirmFocusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
    _saveCurrentScreen();
  }

  Future<void> _saveCurrentScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("last_screen", "create_pin");
  }

  @override
  void dispose() {
    for (var controller in _enterControllers) {
      controller.dispose();
    }
    for (var node in _enterFocusNodes) {
      node.dispose();
    }
    for (var controller in _confirmControllers) {
      controller.dispose();
    }
    for (var node in _confirmFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<bool> savePin(String pin) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final pinHash = sha256.convert(utf8.encode(pin)).toString();

      await _supabase
          .from("app_users")
          .update({
            "pin_hash": pinHash,
            "updated_at": DateTime.now().toIso8601String(),
          })
          .eq("id", user.id);

      return true;
    } catch (e) {
      debugPrint("Save Pin Error: $e");
      return false;
    }
  }

  void _clearPinFields() {
    for (final controller in _enterControllers) {
      controller.clear();
    }
    for (final controller in _confirmControllers) {
      controller.clear();
    }
    _enterFocusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final bool isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: !isDesktop ? 50 : 60,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: isDesktop ? _buildDesktopView(screenWidth) : _buildMobileView(),
      ),
    );
  }

  // ==================== MOBILE VIEW (Updated for Better Alignment) ====================
  Widget _buildMobileView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Titles
            const Text(
              "Create your PIN",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Set a 4-digit PIN to help keep your account secure.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // SECTION 1: Enter your PIN
            const Text(
              "Enter your PIN",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (index) => _buildPinField(
                  index: index,
                  isMobile: true,
                  controllers: _enterControllers,
                  focusNodes: _enterFocusNodes,
                  nextFocusNodes: _confirmFocusNodes,
                  isConfirmRow: false,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // SECTION 2: Confirm your PIN
            const Text(
              "Confirm your PIN",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (index) => _buildPinField(
                  index: index,
                  isMobile: true,
                  controllers: _confirmControllers,
                  focusNodes: _confirmFocusNodes,
                  nextFocusNodes: null,
                  isConfirmRow: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DESKTOP VIEW (Unchanged) ====================
  Widget _buildDesktopView(double screenWidth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isShortScreen = constraints.maxHeight < 620;
        final bool isExtremelyNarrow = constraints.maxWidth < 280;

        return Stack(
          children: [
            if (constraints.maxWidth > 320)
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
            if (!isShortScreen && constraints.maxWidth > 350)
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create your PIN",
                          style: TextStyle(
                            fontSize: isExtremelyNarrow ? 22 : 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Set a 4-digit PIN to help keep your account secure.",
                          style: TextStyle(
                            fontSize: isExtremelyNarrow ? 11 : 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 36),
                        const Text(
                          "Enter your PIN",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 10),
                        RepaintBoundary(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: List.generate(
                              4,
                              (index) => _buildPinField(
                                index: index,
                                isMobile: false,
                                controllers: _enterControllers,
                                focusNodes: _enterFocusNodes,
                                nextFocusNodes: _confirmFocusNodes,
                                isConfirmRow: false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          "Confirm your PIN",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 10),
                        RepaintBoundary(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: List.generate(
                              4,
                              (index) => _buildPinField(
                                index: index,
                                isMobile: false,
                                controllers: _confirmControllers,
                                focusNodes: _confirmFocusNodes,
                                nextFocusNodes: null,
                                isConfirmRow: true,
                              ),
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
    );
  }

  // Common Flexible Builder for PIN boxes inside Row
  Widget _buildPinField({
    required int index,
    required bool isMobile,
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required List<FocusNode>? nextFocusNodes,
    required bool isConfirmRow,
  }) {
    return SizedBox(
      width: isMobile ? 65 : 64,
      height: isMobile ? 65 : 64,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (controllers[index].text.isEmpty) {
              if (index > 0) {
                focusNodes[index - 1].requestFocus();
              } else if (index == 0 && isConfirmRow) {
                _enterFocusNodes[3].requestFocus();
              }
            }
          }
        },
        child: Container(
          margin: isMobile
              ? EdgeInsets.zero
              : const EdgeInsets.only(right: 10.0),
          decoration: BoxDecoration(
            color: const Color(0xFFECEFF1).withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: TextFormField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              textAlign: TextAlign.center,
              obscureText: true,
              obscuringCharacter: "●",
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
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
                    focusNodes[index + 1].requestFocus();
                  } else {
                    if (nextFocusNodes != null && nextFocusNodes.isNotEmpty) {
                      nextFocusNodes[0].requestFocus();
                    } else {
                      focusNodes[index].unfocus();
                      _handlePinSubmission();
                    }
                  }
                } else {
                  if (index > 0) {
                    focusNodes[index - 1].requestFocus();
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePinSubmission() async {
    String pin = _enterControllers.map((e) => e.text).join();
    String confirmPin = _confirmControllers.map((e) => e.text).join();

    if (pin.length == 4 && confirmPin.length == 4) {
      if (pin == confirmPin) {
        bool success = await savePin(pin);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PIN created successfully")),
        );

        if (success) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("last_screen", "home");
          _clearPinFields();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CreateAccount()),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Failed to save PIN")));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("PINs do not match")));
      }
    }
  }
}

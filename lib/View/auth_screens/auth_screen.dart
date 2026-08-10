import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:qistx_app/View/auth_screens/auth_confirmation_pin.dart';
import 'package:qistx_app/View/auth_screens/auth_create_pin.dart';
import 'package:qistx_app/View/auth_screens/pin_verification_screen.dart';
import 'package:qistx_app/View/users_screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  StreamSubscription<AuthState>? _authSubscription;
  final supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  String email = "";

  // Loading state to fix freeze loop
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;

      if (session != null) {
        // State update safely to show loader while checking DB
        if (mounted) setState(() => _isLoading = true);

        final user = supabase.auth.currentUser;
        if (user != null) {
          final pinResponse = await supabase
              .from("app_users")
              .select("pin_hash")
              .eq("id", user.id)
              .single();

          final hasPin = pinResponse["pin_hash"] != null;

          if (!mounted) return;
          setState(() => _isLoading = false);

          if (hasPin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PinVerificationScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AuthCreatePin()),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    // Crucial Fix: Cancel subscription to prevent background leaks/crashes
    _authSubscription?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  /////////////////// Signin With Google //////
  Future<void> signInWithGoogle() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'qistxapp://login-call', // Supabase dashboard match
        queryParams: {'prompt': 'select_account'},
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  ////////////// Send Otp ////////
  Future<void> sendOtp() async {
    email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter email")));
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithOtp(email: email);

      if (mounted) setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("OTP sent successfully")));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("last_screen", "otp");
      await prefs.setString("otp_email", email);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AuthConfirmationPin(email: email)),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: isDesktop
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40.0,
                          vertical: 24.0,
                        ),
                        child: _buildDesktopLayout(context),
                      ),
                    )
                  // Mobile ke liye hum LayoutBuilder use karenge taake exact height mil sake
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          // Agar screen itni choti hai ke form fit ho sakta hai bina scroll ke,
                          // toh physics disable kar denge taake scroll na ho.
                          // Agar phir bhi overflow ho toh scroll on ho jayega.
                          physics: constraints.maxHeight < 700
                              ? const BouncingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 16.0,
                              ),
                              child: Center(
                                child: _buildMobileLayout(
                                  context,
                                  constraints.maxHeight,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF5F00),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- Mobile/Tablet Layout ----
  Widget _buildMobileLayout(BuildContext context, double screenHeight) {
    // Agar screen ki height bohat choti hai (jaise chote Android phones), toh image ko chhupa denge taake overflow na ho
    bool showImage = screenHeight > 600;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 450),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showImage) ...[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.22),
              child: _build3DPlaceholder(
                imagePath: "assets/images/auth_image.png",
              ),
            ),
            const SizedBox(height: 20),
          ],
          Flexible(child: _buildAuthForm()),
        ],
      ),
    );
  }

  // ---- Desktop Layout ----
  Widget _buildDesktopLayout(BuildContext context) {
    const double desktopContainerHeight = 650.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            height: desktopContainerHeight,
            child: _build3DPlaceholder(
              imagePath: "assets/images/auth_image.png",
              overlayContent: [
                Image.asset(
                  "assets/Icons/Qist_Logo_trans.png",
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 80),
        Expanded(
          flex: 4,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: desktopContainerHeight,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildAuthForm(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Main Auth Form ----
  Widget _buildAuthForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Welcome\nto QistX",
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            height: 1.15,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 36),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "Email",
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.email_outlined, color: Colors.grey),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => sendOtp(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5F00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              "Forget your password? ",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuthConfirmationPin(email: email),
                  ),
                );
              },
              child: const Text(
                "Reset",
                style: TextStyle(
                  color: Color(0xFFFF5F00),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Row(
          children: [
            Expanded(child: Divider(color: Colors.black12, thickness: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Or sign in with",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            Expanded(child: Divider(color: Colors.black12, thickness: 1)),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildSocialButton(
                "assets/Icons/google.png",
                signInWithGoogle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSocialButton("assets/Icons/Appleicon.png", () {}),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSocialButton("assets/Icons/phone.png", () {}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(String imagePath, VoidCallback onTap) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            imagePath,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _build3DPlaceholder({
    required String imagePath,
    List<Widget>? overlayContent,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),
              if (overlayContent != null && overlayContent.isNotEmpty)
                Positioned(
                  top: 40,
                  left: 40,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: overlayContent,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:qistx_app/View/auth_screens/auth_confirmation_pin.dart';
import 'package:qistx_app/View/auth_screens/auth_create_pin.dart';
import 'package:qistx_app/View/auth_screens/auth_screen.dart';
import 'package:qistx_app/View/auth_screens/pin_verification_screen.dart';
import 'package:qistx_app/View/profilecreation/create_account.dart';
import 'package:qistx_app/View/profilecreation/create_shop_profile.dart';
import 'package:qistx_app/View/users_screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    nextscreen();
  }

  Future<void> nextscreen() async {
    debugPrint("SPLASH: nextscreen started");
    await Future.delayed(const Duration(seconds: 3));
    debugPrint("SPLASH: 3 seconds completed");

    final prefs = await SharedPreferences.getInstance();
    debugPrint("SPLASH: SharedPreferences completed");

    final lastScreen = prefs.getString("last_screen");
    final email = prefs.getString("otp_email");
    debugPrint("SPLASH: lastScreen = $lastScreen");
    debugPrint("SPLASH: email = $email");

    // ==========================
    // OTP SCREEN RESTORE FIRST
    // ==========================
    if (lastScreen == "otp" && email != null && email.isNotEmpty) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthConfirmationPin(email: email)),
      );
      return;
    }

    // ==========================
    // CHECK LOGIN
    // ==========================
    final user = supabase.auth.currentUser;
    debugPrint("SPLASH: user = ${user?.id}");

    if (user == null) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    // ==========================
    // RESTORE OTHER SCREENS
    // ==========================
    if (!mounted) return;

    switch (lastScreen) {
      case "create_pin":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthCreatePin()),
        );
        return;

      case "complete_account":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreateAccount()),
        );
        return;
      case "create_shop_profile":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreateShopProfile()),
        );
        return;
      // case "create_customer_profile":
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (_) => const CreateCustomerProfile()),
      //   );
      //   return;

      case "pin_verification":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PinVerificationScreen()),
        );
        return;
      // case "add_new_product":
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (_) => const AddNewProduct()),
      //   );
      //   return;
      // case "customer-khata":
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (_) => const CustomerKhata()),
      //   );
      //   return;

      // case "AddLedger":
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (_) => const AddLedger()),
      //   );
      //   return;

      case "home":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
    }

    // ==========================
    // DEFAULT FLOW
    // ==========================
    try {
      final response = await supabase
          .from("app_users")
          .select("pin_hash")
          .eq("id", user.id)
          .single();

      final hasPin = response["pin_hash"] != null;

      if (!mounted) return;

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
    } catch (e) {
      debugPrint("Splash Error: $e");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    /// To get the current screen height and width
    final size = MediaQuery.of(context).size;

    /// width aur height mein se chhoti dimension leta hai.
    final logoSize = size.shortestSide * 0.35;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/icons/Qist_Logo_trans.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

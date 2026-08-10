import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  static const String _biometricKey = 'biometric_enabled';

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      print('isDeviceSupported error: $e');
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      print('canCheckBiometrics error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      print('getAvailableBiometrics error: $e');
      return [];
    }
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    final result = await prefs.setBool(_biometricKey, value);

    print('Saving biometric: $value');
    print('SharedPreferences save result: $result');
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getBool(_biometricKey) ?? false;

    print('Reading biometric: $value');

    return value;
  }

  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_biometricKey, false);
  }
}

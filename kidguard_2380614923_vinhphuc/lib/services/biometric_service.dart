import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('getAvailableBiometrics error: $e');
      return [];
    }
  }

  Future<bool> authenticate({
    required String reason,
  }) async {
    try {
      final isAvailable = await canAuthenticate();
      if (!isAvailable) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric platform exception: $e');
      return false;
    } catch (e) {
      debugPrint('Biometric general exception: $e');
      return false;
    }
  }
}

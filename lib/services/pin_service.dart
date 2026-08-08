import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';

class PinService {
  static const String _keyFailedAttempts = 'failed_pin_attempts';
  static const String _keyLockoutUntil = 'pin_lockout_until';

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(AppConstants.prefsPinKey);
    return pin != null && pin.trim().isNotEmpty;
  }

  Future<int> getRemainingLockoutSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntilMillis = prefs.getInt(_keyLockoutUntil) ?? 0;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    if (lockoutUntilMillis > nowMillis) {
      return ((lockoutUntilMillis - nowMillis) / 1000).ceil();
    }
    return 0;
  }

  Future<int> getFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFailedAttempts) ?? 0;
  }

  Future<bool> verifyPin(String pinInput) async {
    final remainingLockout = await getRemainingLockoutSeconds();
    if (remainingLockout > 0) {
      throw Exception('Akses terkunci! Silakan tunggu $remainingLockout detik lagi.');
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(AppConstants.prefsPinKey);
    if (savedPin == null || savedPin.isEmpty) {
      return true; // No PIN set yet
    }

    final hashedInput = _hashPin(pinInput);
    bool isValid = false;

    // Backward compatibility for legacy plain text PIN (length 6) vs SHA-256 hash (length 64)
    if (savedPin.length == 6) {
      isValid = (savedPin == pinInput.trim());
      if (isValid) {
        // Upgrade legacy plain text PIN to SHA-256 hash
        await prefs.setString(AppConstants.prefsPinKey, hashedInput);
      }
    } else {
      isValid = (savedPin == hashedInput);
    }

    if (isValid) {
      await prefs.remove(_keyFailedAttempts);
      await prefs.remove(_keyLockoutUntil);
      return true;
    } else {
      int attempts = (prefs.getInt(_keyFailedAttempts) ?? 0) + 1;
      if (attempts >= 5) {
        final lockoutTime = DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch;
        await prefs.setInt(_keyLockoutUntil, lockoutTime);
        await prefs.setInt(_keyFailedAttempts, 0);
        throw Exception('PIN salah 5x! Akses terkunci selama 30 detik.');
      } else {
        await prefs.setInt(_keyFailedAttempts, attempts);
        final remaining = 5 - attempts;
        throw Exception('PIN salah! Sisa percobaan: $remaining kali.');
      }
    }
  }

  Future<bool> setPin(String newPin) async {
    final trimmed = newPin.trim();
    if (trimmed.length != 6 || int.tryParse(trimmed) == null) {
      throw Exception('PIN harus terdiri dari 6 angka digit!');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFailedAttempts);
    await prefs.remove(_keyLockoutUntil);
    final hashedPin = _hashPin(trimmed);
    return await prefs.setString(AppConstants.prefsPinKey, hashedPin);
  }

  Future<bool> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFailedAttempts);
    await prefs.remove(_keyLockoutUntil);
    return await prefs.remove(AppConstants.prefsPinKey);
  }
}

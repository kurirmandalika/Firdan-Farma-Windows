import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';

class PinService {
  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(AppConstants.prefsPinKey);
    return pin != null && pin.trim().isNotEmpty;
  }

  Future<bool> verifyPin(String pinInput) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(AppConstants.prefsPinKey);
    if (savedPin == null || savedPin.isEmpty) {
      return true; // No PIN set yet
    }
    return savedPin == pinInput.trim();
  }

  Future<bool> setPin(String newPin) async {
    if (newPin.trim().length != 6) {
      throw Exception('PIN harus terdiri dari 6 angka digit!');
    }
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(AppConstants.prefsPinKey, newPin.trim());
  }

  Future<bool> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(AppConstants.prefsPinKey);
  }
}

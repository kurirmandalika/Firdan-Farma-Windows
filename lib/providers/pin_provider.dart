import 'package:flutter/material.dart';
import '../services/pin_service.dart';

class PinProvider extends ChangeNotifier {
  final PinService _service = PinService();

  bool _isUnlocked = false;
  bool get isUnlocked => _isUnlocked;

  bool _hasPinSet = false;
  bool get hasPinSet => _hasPinSet;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  PinProvider() {
    checkPinState();
  }

  Future<void> checkPinState() async {
    _isLoading = true;
    notifyListeners();

    _hasPinSet = await _service.hasPin();
    if (!_hasPinSet) {
      _isUnlocked = true; // Auto unlock if no PIN set yet
    } else {
      _isUnlocked = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> unlock(String pin) async {
    final valid = await _service.verifyPin(pin);
    if (valid) {
      _isUnlocked = true;
      notifyListeners();
    }
    return valid;
  }

  void lockApp() {
    if (_hasPinSet) {
      _isUnlocked = false;
      notifyListeners();
    }
  }

  Future<bool> setupNewPin(String pin) async {
    final success = await _service.setPin(pin);
    if (success) {
      _hasPinSet = true;
      _isUnlocked = true;
      notifyListeners();
    }
    return success;
  }

  Future<bool> resetPin() async {
    final success = await _service.removePin();
    if (success) {
      _hasPinSet = false;
      _isUnlocked = true;
      notifyListeners();
    }
    return success;
  }
}

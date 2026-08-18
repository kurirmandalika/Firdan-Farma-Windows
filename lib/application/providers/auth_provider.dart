import 'package:flutter/material.dart';
import 'package:firdan_farma_windows/data/models/user_model.dart';
import 'package:firdan_farma_windows/data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  UserAccount? _currentUser;
  UserAccount? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isSuperAdmin => _currentUser?.isSuperAdmin == true;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AuthProvider() {
    initialize();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.ensureDefaultUsers();
      _currentUser = AuthSession.currentUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _service.login(username, password);
      _currentUser = user;
      return user != null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<List<UserAccount>> getUsers() => _service.getUsers();

  Future<void> saveUser({
    int? id,
    required String username,
    required String namaTampilan,
    required String role,
    String? password,
    bool isActive = true,
  }) async {
    if (!isSuperAdmin) {
      throw Exception('Hanya Super Admin yang dapat mengubah pengguna.');
    }
    await _service.saveUser(
      id: id,
      username: username,
      namaTampilan: namaTampilan,
      role: role,
      password: password,
      isActive: isActive,
    );
    notifyListeners();
  }
}

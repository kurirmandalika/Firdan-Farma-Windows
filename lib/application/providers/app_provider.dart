import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/data/services/spreadsheet_service.dart';

class AppProvider extends ChangeNotifier {
  static const _prefsDarkModeKey = 'is_dark_mode';

  final SpreadsheetService _spreadsheetService = SpreadsheetService();

  int _selectedNavIndex = 0;
  int get selectedNavIndex => _selectedNavIndex;

  bool _isSidebarCollapsed = false;
  bool get isSidebarCollapsed => _isSidebarCollapsed;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  String? _connectedSpreadsheetPath;
  String? get connectedSpreadsheetPath => _connectedSpreadsheetPath;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _notificationMessage;
  String? get notificationMessage => _notificationMessage;

  AppProvider() {
    _initThemeMode();
    _initSpreadsheetStatus();
  }

  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  void setSidebarCollapsed(bool value) {
    _isSidebarCollapsed = value;
    notifyListeners();
  }

  Future<void> _initThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_prefsDarkModeKey) ?? false;
    AppTheme.setBrightness(_isDarkMode ? Brightness.dark : Brightness.light);
    notifyListeners();
  }

  Future<void> toggleThemeMode() async {
    _isDarkMode = !_isDarkMode;
    AppTheme.setBrightness(_isDarkMode ? Brightness.dark : Brightness.light);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsDarkModeKey, _isDarkMode);
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _initSpreadsheetStatus() async {
    _connectedSpreadsheetPath = await _spreadsheetService
        .getConnectedSpreadsheetPath();
    notifyListeners();
  }

  void updateSpreadsheetPath(String? path) {
    _connectedSpreadsheetPath = path;
    notifyListeners();
  }

  void showNotification(String msg) {
    _notificationMessage = msg;
    notifyListeners();
  }
}

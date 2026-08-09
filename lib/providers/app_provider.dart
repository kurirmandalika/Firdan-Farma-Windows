import 'package:flutter/material.dart';
import '../services/spreadsheet_service.dart';

class AppProvider extends ChangeNotifier {
  final SpreadsheetService _spreadsheetService = SpreadsheetService();

  int _selectedNavIndex = 0;
  int get selectedNavIndex => _selectedNavIndex;

  bool _isSidebarCollapsed = false;
  bool get isSidebarCollapsed => _isSidebarCollapsed;

  String? _connectedSpreadsheetPath;
  String? get connectedSpreadsheetPath => _connectedSpreadsheetPath;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _notificationMessage;
  String? get notificationMessage => _notificationMessage;

  AppProvider() {
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

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _initSpreadsheetStatus() async {
    _connectedSpreadsheetPath = await _spreadsheetService.getConnectedSpreadsheetPath();
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

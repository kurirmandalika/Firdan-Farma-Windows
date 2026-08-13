import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firdan_farma_windows/data/models/obat_model.dart';
import 'package:firdan_farma_windows/data/services/obat_service.dart';

class ObatProvider extends ChangeNotifier {
  final ObatService _service = ObatService();

  List<Obat> _obatList = [];
  List<Obat> get obatList => _obatList;

  List<Obat> _lowStockList = [];
  List<Obat> get lowStockList => _lowStockList;

  int _totalActiveCount = 0;
  int get totalActiveCount => _totalActiveCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int? _selectedKategoriId;
  int? get selectedKategoriId => _selectedKategoriId;

  bool _showInactive = false;
  bool get showInactive => _showInactive;

  Timer? _searchDebounce;
  int _fetchToken = 0;

  Future<void> fetchObat() async {
    final token = ++_fetchToken;
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _service.getAll(
          searchQuery: _searchQuery,
          kategoriId: _selectedKategoriId,
          includeInactive: _showInactive,
        ),
        _service.getLowStock(),
        _service.countActive(),
      ]);
      if (token == _fetchToken) {
        _obatList = results[0] as List<Obat>;
        _lowStockList = results[1] as List<Obat>;
        _totalActiveCount = results[2] as int;
      }
    } catch (e) {
      debugPrint('Error fetchObat: $e');
    } finally {
      if (token == _fetchToken) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchDashboardSummary() async {
    try {
      final count = await _service.countActive();
      final lowStock = await _service.getLowStock();
      _totalActiveCount = count;
      _lowStockList = lowStock;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetchDashboardSummary: $e');
    }
  }

  void setShowInactive(bool value) {
    if (_showInactive == value) return;
    _showInactive = value;
    _searchDebounce?.cancel();
    fetchObat();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), fetchObat);
    notifyListeners();
  }

  void setKategoriFilter(int? kategoriId) {
    if (_selectedKategoriId == kategoriId) return;
    _selectedKategoriId = kategoriId;
    _searchDebounce?.cancel();
    fetchObat();
  }

  Future<bool> addObat(Obat obat) async {
    try {
      await _service.insert(obat);
      await fetchObat();
      return true;
    } catch (e) {
      debugPrint('Error addObat: $e');
      rethrow;
    }
  }

  Future<bool> updateObat(Obat obat) async {
    try {
      await _service.update(obat);
      await fetchObat();
      return true;
    } catch (e) {
      debugPrint('Error updateObat: $e');
      rethrow;
    }
  }

  Future<bool> deleteObat(int id) async {
    try {
      await _service.delete(id);
      await fetchObat();
      return true;
    } catch (e) {
      debugPrint('Error deleteObat: $e');
      rethrow;
    }
  }

  Future<bool> reactivateObat(int id) async {
    try {
      await _service.reactivate(id);
      await fetchObat();
      return true;
    } catch (e) {
      debugPrint('Error reactivateObat: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

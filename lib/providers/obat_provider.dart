import 'package:flutter/material.dart';
import '../models/obat_model.dart';
import '../services/obat_service.dart';

class ObatProvider extends ChangeNotifier {
  final ObatService _service = ObatService();

  List<Obat> _obatList = [];
  List<Obat> get obatList => _obatList;

  List<Obat> _lowStockList = [];
  List<Obat> get lowStockList => _lowStockList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int? _selectedKategoriId;
  int? get selectedKategoriId => _selectedKategoriId;

  bool _showInactive = false;
  bool get showInactive => _showInactive;

  Future<void> fetchObat() async {
    _isLoading = true;
    notifyListeners();

    try {
      _obatList = await _service.getAll(
        searchQuery: _searchQuery,
        kategoriId: _selectedKategoriId,
        includeInactive: _showInactive,
      );
      _lowStockList = await _service.getLowStock();
    } catch (e) {
      debugPrint('Error fetchObat: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setShowInactive(bool value) {
    _showInactive = value;
    fetchObat();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchObat();
  }

  void setKategoriFilter(int? kategoriId) {
    _selectedKategoriId = kategoriId;
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
}

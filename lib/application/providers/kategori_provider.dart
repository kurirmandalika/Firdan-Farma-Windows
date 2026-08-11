import 'package:flutter/material.dart';
import 'package:firdan_farma_windows/data/models/kategori_model.dart';
import 'package:firdan_farma_windows/data/services/kategori_service.dart';

class KategoriProvider extends ChangeNotifier {
  final KategoriService _service = KategoriService();

  List<KategoriObat> _kategoriList = [];
  List<KategoriObat> get kategoriList => _kategoriList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchKategori() async {
    _isLoading = true;
    notifyListeners();

    try {
      _kategoriList = await _service.getAll();
    } catch (e) {
      debugPrint('Error fetchKategori: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addKategori(KategoriObat kategori) async {
    await _service.insert(kategori);
    await fetchKategori();
    return true;
  }

  Future<bool> updateKategori(KategoriObat kategori) async {
    await _service.update(kategori);
    await fetchKategori();
    return true;
  }

  Future<bool> deleteKategori(int id) async {
    await _service.delete(id);
    await fetchKategori();
    return true;
  }
}

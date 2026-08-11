import 'package:flutter/material.dart';
import 'package:firdan_farma_windows/data/services/laporan_service.dart';

class LaporanProvider extends ChangeNotifier {
  final LaporanService _service = LaporanService();

  DateTime _dariTanggal = DateTime.now().subtract(const Duration(days: 30));
  DateTime get dariTanggal => _dariTanggal;

  DateTime _sampaiTanggal = DateTime.now();
  DateTime get sampaiTanggal => _sampaiTanggal;

  LaporanRingkasan? _ringkasan;
  LaporanRingkasan? get ringkasan => _ringkasan;

  List<ObatTerlarisItem> _obatTerlaris = [];
  List<ObatTerlarisItem> get obatTerlaris => _obatTerlaris;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchLaporan() async {
    _isLoading = true;
    notifyListeners();

    try {
      _ringkasan = await _service.getRingkasan(_dariTanggal, _sampaiTanggal);
      _obatTerlaris = await _service.getObatTerlaris(
        _dariTanggal,
        _sampaiTanggal,
        limit: 5,
      );
    } catch (e) {
      debugPrint('Error fetchLaporan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setDateRange(DateTime dari, DateTime sampai) {
    _dariTanggal = dari;
    _sampaiTanggal = sampai;
    fetchLaporan();
  }
}

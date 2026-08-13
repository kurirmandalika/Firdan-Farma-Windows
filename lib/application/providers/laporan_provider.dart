import 'package:flutter/material.dart';
import 'package:firdan_farma_windows/data/services/laporan_service.dart';

class LaporanProvider extends ChangeNotifier {
  final LaporanService _service = LaporanService();

  DateTime _dariTanggal = DateTime.now();
  DateTime get dariTanggal => _dariTanggal;

  DateTime _sampaiTanggal = DateTime.now();
  DateTime get sampaiTanggal => _sampaiTanggal;

  LaporanRingkasan? _ringkasan;
  LaporanRingkasan? get ringkasan => _ringkasan;

  List<ObatTerlarisItem> _obatTerlaris = [];
  List<ObatTerlarisItem> get obatTerlaris => _obatTerlaris;

  List<MedicinePeriodReport> _medicineReports = [];
  List<MedicinePeriodReport> get medicineReports => _medicineReports;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchLaporan() async {
    _isLoading = true;
    notifyListeners();

    try {
      _ringkasan = await _service.getRingkasan(_dariTanggal, _sampaiTanggal);
      final results = await Future.wait([
        _service.getObatTerlaris(_dariTanggal, _sampaiTanggal, limit: 5),
        _service.getMedicinePeriodReports(_dariTanggal, _sampaiTanggal),
      ]);
      _obatTerlaris = results[0] as List<ObatTerlarisItem>;
      _medicineReports = results[1] as List<MedicinePeriodReport>;
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

  void setToday() {
    final now = DateTime.now();
    setDateRange(now, now);
  }

  void setYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    setDateRange(yesterday, yesterday);
  }

  void setLast7Days() {
    final now = DateTime.now();
    setDateRange(now.subtract(const Duration(days: 6)), now);
  }

  void setThisMonth() {
    final now = DateTime.now();
    setDateRange(DateTime(now.year, now.month), now);
  }
}

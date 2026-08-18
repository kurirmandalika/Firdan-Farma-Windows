import 'package:flutter/material.dart';
import 'package:firdan_farma_windows/data/models/audit_log_model.dart';
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

  List<SalesPaymentSummary> _paymentSummaries = [];
  List<SalesPaymentSummary> get paymentSummaries => _paymentSummaries;

  List<AuditLog> _activityLogs = [];
  List<AuditLog> get activityLogs => _activityLogs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> fetchLaporan() async {
    if (_disposed) return;
    _isLoading = true;
    notifyListeners();

    try {
      _ringkasan = await _service.getRingkasan(_dariTanggal, _sampaiTanggal);
      if (_disposed) return;
      final results = await Future.wait([
        _service.getObatTerlaris(_dariTanggal, _sampaiTanggal, limit: 5),
        _service.getMedicinePeriodReports(_dariTanggal, _sampaiTanggal),
        _service.getPaymentSummaries(_dariTanggal, _sampaiTanggal),
      ]);
      _obatTerlaris = results[0] as List<ObatTerlarisItem>;
      _medicineReports = results[1] as List<MedicinePeriodReport>;
      _paymentSummaries = results[2] as List<SalesPaymentSummary>;
      _activityLogs = await _service.getActivityLogs(limit: 100);
      if (_disposed) return;
    } catch (e) {
      debugPrint('Error fetchLaporan: $e');
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
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

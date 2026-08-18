import 'package:flutter/material.dart';
import 'package:firdan_farma_windows/data/models/stok_model.dart';
import 'package:firdan_farma_windows/data/services/stok_service.dart';

class StokProvider extends ChangeNotifier {
  final StokService _service = StokService();

  List<StokMutasi> _mutasiList = [];
  List<StokMutasi> get mutasiList => _mutasiList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchMutasi() async {
    _isLoading = true;
    notifyListeners();

    try {
      _mutasiList = await _service.getAllMutasi();
    } catch (e) {
      debugPrint('Error fetchMutasi: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStok({
    required int obatId,
    required String jenis,
    required int jumlah,
    String? alasan,
    double? hargaBeli,
    String? catatan,
    String? batchNo,
    String? expiredDate,
  }) async {
    final success = await _service.updateStok(
      obatId: obatId,
      jenis: jenis,
      jumlah: jumlah,
      alasan: alasan,
      hargaBeli: hargaBeli,
      catatan: catatan,
      batchNo: batchNo,
      expiredDate: expiredDate,
    );
    if (success) {
      await fetchMutasi();
    }
    return success;
  }
}

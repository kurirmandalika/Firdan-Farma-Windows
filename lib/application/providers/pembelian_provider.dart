import 'package:flutter/material.dart';
import 'package:firdan_farma_windows/data/models/detail_pembelian_model.dart';
import 'package:firdan_farma_windows/data/models/obat_model.dart';
import 'package:firdan_farma_windows/data/models/pembelian_model.dart';
import 'package:firdan_farma_windows/data/services/pembelian_service.dart';

class PurchaseCartItem {
  final Obat obat;
  int qty;
  double hargaBeli;
  String? batchNo;
  String? expiredDate;

  PurchaseCartItem({
    required this.obat,
    this.qty = 1,
    required this.hargaBeli,
    this.batchNo,
    this.expiredDate,
  });

  double get subtotal => qty * hargaBeli;
}

class PembelianProvider extends ChangeNotifier {
  final PembelianService _service = PembelianService();

  List<Pembelian> _pembelianList = [];
  List<Pembelian> get pembelianList => _pembelianList;

  final List<PurchaseCartItem> _cartItems = [];
  List<PurchaseCartItem> get cartItems => _cartItems;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _todayPurchaseTotal = 0;
  double get todayPurchaseTotal => _todayPurchaseTotal;

  double get subtotal => _cartItems.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> fetchPembelian() async {
    _isLoading = true;
    notifyListeners();
    try {
      _pembelianList = await _service.getAll();
      _todayPurchaseTotal = await _service.getTodayTotal();
    } catch (e) {
      debugPrint('Error fetchPembelian: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSummary() async {
    try {
      _todayPurchaseTotal = await _service.getTodayTotal();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetchPurchaseSummary: $e');
    }
  }

  void addToCart(Obat obat) {
    final index = _cartItems.indexWhere((item) => item.obat.id == obat.id);
    if (index >= 0) {
      _cartItems[index].qty += 1;
    } else {
      _cartItems.add(PurchaseCartItem(obat: obat, hargaBeli: obat.hargaBeli));
    }
    notifyListeners();
  }

  void updateQty(int obatId, int qty) {
    final index = _cartItems.indexWhere((item) => item.obat.id == obatId);
    if (index < 0) return;
    if (qty <= 0) {
      _cartItems.removeAt(index);
    } else {
      _cartItems[index].qty = qty;
    }
    notifyListeners();
  }

  void updateHargaBeli(int obatId, double hargaBeli) {
    final index = _cartItems.indexWhere((item) => item.obat.id == obatId);
    if (index < 0) return;
    _cartItems[index].hargaBeli = hargaBeli;
    notifyListeners();
  }

  void updateBatch(int obatId, String? batchNo) {
    final index = _cartItems.indexWhere((item) => item.obat.id == obatId);
    if (index < 0) return;
    _cartItems[index].batchNo = batchNo?.trim();
    notifyListeners();
  }

  void updateExpiredDate(int obatId, String? expiredDate) {
    final index = _cartItems.indexWhere((item) => item.obat.id == obatId);
    if (index < 0) return;
    _cartItems[index].expiredDate = expiredDate;
    notifyListeners();
  }

  void removeFromCart(int obatId) {
    _cartItems.removeWhere((item) => item.obat.id == obatId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<Pembelian> savePembelian({
    int? supplierId,
    DateTime? tanggal,
    String? nomorFaktur,
    double diskon = 0,
    String? catatan,
  }) async {
    if (_isLoading) {
      throw Exception('Pembelian sedang diproses. Tunggu sebentar.');
    }
    if (_cartItems.isEmpty) {
      throw Exception('Tambahkan minimal satu obat pada pembelian.');
    }
    _isLoading = true;
    notifyListeners();
    try {
      final details = _cartItems
          .map(
            (item) => DetailPembelian(
              obatId: item.obat.id!,
              qty: item.qty,
              hargaBeli: item.hargaBeli,
              namaObat: item.obat.nama,
              kodeObat: item.obat.kodeObat,
              satuan: item.obat.satuan,
              batchNo: item.batchNo,
              expiredDate: item.expiredDate,
            ),
          )
          .toList();
      final result = await _service.createPembelian(
        supplierId: supplierId,
        tanggal: tanggal,
        nomorFaktur: nomorFaktur,
        diskon: diskon,
        catatan: catatan,
        items: details,
      );
      clearCart();
      await fetchPembelian();
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

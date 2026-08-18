import 'package:flutter/material.dart';
import 'package:firdan_farma_windows/data/models/detail_transaksi_model.dart';
import 'package:firdan_farma_windows/data/models/obat_model.dart';
import 'package:firdan_farma_windows/data/models/transaksi_model.dart';
import 'package:firdan_farma_windows/data/services/transaksi_service.dart';

class CartItem {
  final Obat obat;
  int jumlah;

  CartItem({required this.obat, this.jumlah = 1});

  double get subtotal => obat.hargaJual * jumlah;
}

class TransaksiProvider extends ChangeNotifier {
  final TransaksiService _service = TransaksiService();

  static const paymentMethods = ['TUNAI', 'QRIS', 'TRANSFER', 'LAINNYA'];

  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;

  List<Transaksi> _transaksiList = [];
  List<Transaksi> get transaksiList => _transaksiList;

  double _bayar = 0.0;
  double get bayar => _bayar;

  String _metodePembayaran = 'TUNAI';
  String get metodePembayaran => _metodePembayaran;

  double _diskon = 0;
  double get diskon => _diskon;
  bool _diberiDiskon = false;
  bool get diberiDiskon => _diberiDiskon;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _todayTxCount = 0;
  int get todayTxCount => _todayTxCount;

  double _todayRevenue = 0.0;
  double get todayRevenue => _todayRevenue;

  double _todayGrossProfit = 0.0;
  double get todayGrossProfit => _todayGrossProfit;

  double get totalBelanja =>
      _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalTagihan => (totalBelanja - _diskon).clamp(0, double.infinity);
  double get effectiveBayar =>
      _metodePembayaran == 'TUNAI' ? _bayar : totalTagihan;
  double get kembali => (_metodePembayaran == 'TUNAI' && _bayar >= totalTagihan)
      ? (_bayar - totalTagihan)
      : 0.0;
  int get totalItemCount =>
      _cartItems.fold(0, (sum, item) => sum + item.jumlah);

  Future<void> fetchSummary() async {
    try {
      final results = await Future.wait([
        _service.getTodayCount(),
        _service.getTodayRevenue(),
        _service.getTodayGrossProfit(),
      ]);
      _todayTxCount = results[0] as int;
      _todayRevenue = results[1] as double;
      _todayGrossProfit = results[2] as double;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetchSummary: $e');
    }
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transaksiList = await _service.getAll(limit: 100);
      await fetchSummary();
    } catch (e) {
      debugPrint('Error fetchHistory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addToCart(Obat obat) {
    // Check stock available
    final existingIndex = _cartItems.indexWhere(
      (item) => item.obat.id == obat.id,
    );
    if (existingIndex >= 0) {
      if (_cartItems[existingIndex].jumlah < obat.stokTersedia) {
        _cartItems[existingIndex].jumlah += 1;
      } else {
        throw Exception(
          'Jumlah item melebihi stok yang tersedia (${obat.stokTersedia})!',
        );
      }
    } else {
      if (obat.stokTersedia > 0) {
        _cartItems.add(CartItem(obat: obat, jumlah: 1));
      } else {
        throw Exception('Stok obat "${obat.nama}" habis!');
      }
    }
    notifyListeners();
  }

  void updateItemQuantity(int obatId, int delta) {
    final index = _cartItems.indexWhere((item) => item.obat.id == obatId);
    if (index >= 0) {
      final newQty = _cartItems[index].jumlah + delta;
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else if (newQty <= _cartItems[index].obat.stokTersedia) {
        _cartItems[index].jumlah = newQty;
      } else {
        throw Exception('Jumlah item melebihi stok yang tersedia!');
      }
      notifyListeners();
    }
  }

  void removeFromCart(int obatId) {
    _cartItems.removeWhere((item) => item.obat.id == obatId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _bayar = 0.0;
    _metodePembayaran = 'TUNAI';
    _diskon = 0;
    _diberiDiskon = false;
    notifyListeners();
  }

  void setDiscount(double amount, {bool applied = true}) {
    _diskon = amount.clamp(0, totalBelanja).toDouble();
    _diberiDiskon = applied;
    if (_metodePembayaran != 'TUNAI') _bayar = totalTagihan;
    notifyListeners();
  }

  void setBayar(double amount) {
    _bayar = amount;
    notifyListeners();
  }

  void setMetodePembayaran(String value) {
    if (!paymentMethods.contains(value)) return;
    _metodePembayaran = value;
    if (value != 'TUNAI') {
      _bayar = totalTagihan;
    }
    notifyListeners();
  }

  Future<Transaksi?> processCheckout() async {
    if (_isLoading) {
      throw Exception('Transaksi sedang diproses. Tunggu sebentar.');
    }
    if (_cartItems.isEmpty) {
      throw Exception('Keranjang belanja masih kosong!');
    }
    if (_metodePembayaran == 'TUNAI' && _bayar < totalTagihan) {
      throw Exception('Nominal pembayaran kurang dari total!');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final detailItems = _cartItems
          .map(
            (item) => DetailTransaksi(
              obatId: item.obat.id!,
              jumlah: item.jumlah,
              hargaSatuan: item.obat.hargaJual,
              hargaModalSatuan: item.obat.hargaBeli,
              subtotal: item.subtotal,
              namaObat: item.obat.nama,
              kodeObat: item.obat.kodeObat,
            ),
          )
          .toList();

      final resultTx = await _service.createTransaksi(
        total: totalTagihan,
        bayar: effectiveBayar,
        metodePembayaran: _metodePembayaran,
        subtotalSebelumDiskon: totalBelanja,
        diskon: _diskon,
        diberiDiskon: _diberiDiskon,
        items: detailItems,
      );

      clearCart();
      await fetchSummary();
      return resultTx;
    } catch (e) {
      debugPrint('Error processCheckout: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

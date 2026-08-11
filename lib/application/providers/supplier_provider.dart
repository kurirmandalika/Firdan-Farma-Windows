import 'package:flutter/material.dart';
import 'package:firdan_farma_windows/data/models/supplier_model.dart';
import 'package:firdan_farma_windows/data/services/supplier_service.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierService _service = SupplierService();

  List<Supplier> _supplierList = [];
  List<Supplier> get supplierList => _supplierList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchSupplier() async {
    _isLoading = true;
    notifyListeners();

    try {
      _supplierList = await _service.getAll();
    } catch (e) {
      debugPrint('Error fetchSupplier: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSupplier(Supplier supplier) async {
    await _service.insert(supplier);
    await fetchSupplier();
    return true;
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    await _service.update(supplier);
    await fetchSupplier();
    return true;
  }

  Future<bool> deleteSupplier(int id) async {
    await _service.delete(id);
    await fetchSupplier();
    return true;
  }
}

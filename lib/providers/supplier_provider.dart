import 'package:flutter/material.dart';
import 'package:pos_rp/models/supplier_model.dart';
import 'package:pos_rp/services/database_helper.dart';

class SupplierProvider with ChangeNotifier {
  List<Supplier> _suppliers = [];
  bool _isLoading = true;

  SupplierProvider() {
    fetchSuppliers();
  }

  List<Supplier> get suppliers => [..._suppliers];
  bool get isLoading => _isLoading;

  Future<void> fetchSuppliers() async {
    _isLoading = true;
    notifyListeners();
    _suppliers = await DatabaseHelper.instance.readAllSuppliers();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSupplier(Supplier supplier) async {
    await DatabaseHelper.instance.createSupplier(supplier);
    await fetchSuppliers(); // Refetch to keep the list sorted
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await DatabaseHelper.instance.updateSupplier(supplier);
    await fetchSuppliers();
  }

  Future<void> deleteSupplier(String id) async {
    await DatabaseHelper.instance.deleteSupplier(id);
    _suppliers.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}

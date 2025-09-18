import 'package:flutter/material.dart';
import 'package:pos_rp/models/purchase_model.dart';
import 'package:pos_rp/services/database_helper.dart';

class PurchaseProvider with ChangeNotifier {
  List<Purchase> _purchases = [];
  bool _isLoading = true;

  PurchaseProvider() {
    fetchPurchases();
  }

  List<Purchase> get purchases => [..._purchases];
  bool get isLoading => _isLoading;

  Future<void> fetchPurchases() async {
    _isLoading = true;
    notifyListeners();
    _purchases = await DatabaseHelper.instance.readAllPurchases();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPurchase(Purchase purchase) async {
    await DatabaseHelper.instance.createPurchase(purchase);
    _purchases.insert(0, purchase);
    notifyListeners();
  }
}

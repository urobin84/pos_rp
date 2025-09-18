import 'package:flutter/material.dart';
import 'package:pos_rp/models/product_model.dart';
import 'package:pos_rp/services/database_helper.dart';

/// Manages the state of products in the application.
class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = true;

  ProductProvider() {
    fetchProducts();
  }

  List<Product> get products => [..._products];
  bool get isLoading => _isLoading;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners(); // Notify listeners that loading has started
    _products = await DatabaseHelper.instance.readAllProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final newProduct = await DatabaseHelper.instance.createProduct(product);
    _products.add(newProduct);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await DatabaseHelper.instance.updateProduct(product);
    final prodIndex = _products.indexWhere((p) => p.id == product.id);
    if (prodIndex >= 0) {
      _products[prodIndex] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Product findById(String id) {
    return _products.firstWhere((prod) => prod.id == id);
  }

  /// Returns a list of best-selling products.
  /// This is a dummy implementation.
  List<Product> get bestSellingProducts {
    // Just returning the first 4 products as a dummy list.
    return _products.take(4).toList();
  }
}

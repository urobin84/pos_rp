import 'package:flutter/material.dart';
import 'package:pos_rp/models/cart_item_model.dart';
import 'package:pos_rp/models/customer_model.dart';

/// Manages the state of the shopping cart.
class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  Customer? _selectedCustomer;

  Customer? get selectedCustomer => _selectedCustomer;

  void selectCustomer(Customer customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void clearCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }

  /// Adds an item to the cart.
  /// If the item is already in the cart, it increases the quantity.
  void addItem(String productId, double price, String name) {
    if (_items.containsKey(productId)) {
      // change quantity...
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: DateTime.now().toString(),
          name: name,
          price: price,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  /// Removes a single item from the cart.
  /// If the quantity is 1, it removes the item completely.
  /// Otherwise, it just decreases the quantity.
  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  /// Removes an item from the cart.
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  /// Clears all items from the cart.
  void clear() {
    _items = {};
    _selectedCustomer = null;
    notifyListeners();
  }
}

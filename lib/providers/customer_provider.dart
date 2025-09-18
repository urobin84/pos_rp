import 'package:flutter/material.dart';
import 'package:pos_rp/models/customer_model.dart';
import 'package:pos_rp/services/database_helper.dart';

class CustomerProvider with ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoading = true;

  CustomerProvider() {
    fetchCustomers();
  }

  List<Customer> get customers => [..._customers];
  bool get isLoading => _isLoading;

  Future<void> fetchCustomers() async {
    _isLoading = true;
    _customers = await DatabaseHelper.instance.readAllCustomers();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCustomer(Customer customer) async {
    final newCustomer = await DatabaseHelper.instance.createCustomer(customer);
    _customers.add(newCustomer);
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    await DatabaseHelper.instance.deleteCustomer(id);
    _customers.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer) async {
    await DatabaseHelper.instance.updateCustomer(customer);
    final custIndex = _customers.indexWhere((c) => c.id == customer.id);
    if (custIndex >= 0) {
      _customers[custIndex] = customer;
      notifyListeners();
    }
  }
}

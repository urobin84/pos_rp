import 'package:flutter/material.dart';
import 'package:pos_rp/models/cart_item_model.dart';
import 'package:pos_rp/models/customer_model.dart';
import 'package:pos_rp/models/transaction_item_model.dart';
import 'package:pos_rp/models/transaction_model.dart';
import 'package:pos_rp/services/database_helper.dart';
import 'package:uuid/uuid.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  TransactionProvider() {
    fetchTransactions();
  }

  List<Transaction> get transactions => [..._transactions];
  bool get isLoading => _isLoading;

  Future<void> fetchTransactions() async {
    _isLoading = true;
    _transactions = await DatabaseHelper.instance.readAllTransactions();
    _isLoading = false;
    notifyListeners();
  }

  Future<Transaction> addTransaction(
    Map<String, CartItem> cartItems,
    double totalAmount,
    String paymentMethod,
    Customer? customer,
  ) async {
    final transactionId = const Uuid().v4();
    final newTransaction = Transaction(
      id: transactionId,
      customerName: customer?.name ?? 'Walk-in Customer',
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
      items:
          cartItems.entries.map((entry) {
            return TransactionItem(
              id: const Uuid().v4(),
              transactionId: transactionId,
              productId: entry.key,
              productName: entry.value.name,
              quantity: entry.value.quantity,
              price: entry.value.price,
            );
          }).toList(),
    );
    await DatabaseHelper.instance.createTransaction(newTransaction);
    _transactions.insert(0, newTransaction); // Add to the top of the list
    notifyListeners();
    return newTransaction;
  }
}

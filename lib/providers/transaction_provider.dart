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

  Future<void> addTransaction(Transaction transaction) async {
    await DatabaseHelper.instance.createTransaction(transaction);
    _transactions.insert(0, transaction); // Add to the top of the list
    notifyListeners();
  }
}

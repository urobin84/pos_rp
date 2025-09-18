import 'package:flutter/material.dart';
import 'package:pos_rp/models/expense_model.dart';
import 'package:pos_rp/services/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = true;

  ExpenseProvider() {
    fetchExpenses();
  }

  List<Expense> get expenses => [..._expenses];
  bool get isLoading => _isLoading;

  Future<void> fetchExpenses() async {
    _isLoading = true;
    notifyListeners();
    _expenses = await DatabaseHelper.instance.readAllExpenses();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await DatabaseHelper.instance.createExpense(expense);
    await fetchExpenses(); // Refetch to keep the list sorted
  }

  Future<void> updateExpense(Expense expense) async {
    await DatabaseHelper.instance.updateExpense(expense);
    await fetchExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}

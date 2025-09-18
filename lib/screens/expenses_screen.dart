import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/providers/expense_provider.dart';
import 'package:pos_rp/widgets/expense_form_dialog.dart';
import 'package:provider/provider.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final expenses = expenseProvider.expenses;
    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Biaya Operasional')),
      body:
          expenseProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : expenses.isEmpty
              ? const Center(
                child: Text(
                  'Belum ada data biaya.',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (ctx, i) {
                  final expense = expenses[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(expense.description),
                      subtitle: Text(
                        '${expense.category} - ${DateFormat('d MMM yyyy').format(expense.date)}',
                      ),
                      trailing: Text(
                        priceFormat.format(expense.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => ExpenseFormDialog(expense: expense),
                        );
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => showDialog(
              context: context,
              builder: (ctx) => const ExpenseFormDialog(),
            ),
        icon: const Icon(Icons.add),
        label: const Text('Catat Biaya'),
      ),
    );
  }
}

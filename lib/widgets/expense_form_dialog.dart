import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/expense_model.dart';
import 'package:pos_rp/providers/expense_provider.dart';
import 'package:pos_rp/widgets/currency_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ExpenseFormDialog extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormDialog({super.key, this.expense});

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _description;
  late double _amount;
  late String _category;
  late DateTime _date;

  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _description = widget.expense!.description;
      _amount = widget.expense!.amount;
      _category = widget.expense!.category;
      _date = widget.expense!.date;
      _amountController.text = _amount.toStringAsFixed(0);
    } else {
      _description = '';
      _amount = 0.0;
      _category = 'Operasional';
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context);

    final finalAmount =
        double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0.0;

    if (widget.expense != null) {
      final updatedExpense = Expense(
        id: widget.expense!.id,
        description: _description,
        amount: finalAmount,
        category: _category,
        date: _date,
      );
      await expenseProvider.updateExpense(updatedExpense);
    } else {
      final newExpense = Expense(
        id: const Uuid().v4(),
        description: _description,
        amount: finalAmount,
        category: _category,
        date: _date,
      );
      await expenseProvider.addExpense(newExpense);
    }

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.expense == null ? 'Tambah Biaya' : 'Edit Biaya'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Deskripsi tidak boleh kosong.' : null,
                onSaved: (value) => _description = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Jumlah'),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                validator:
                    (value) =>
                        value!.isEmpty ? 'Jumlah tidak boleh kosong.' : null,
              ),
              const SizedBox(height: 16),
              // Simple dropdown for category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items:
                    ['Operasional', 'Gaji', 'Sewa', 'Lainnya']
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _saveForm, child: const Text('Simpan')),
      ],
    );
  }
}

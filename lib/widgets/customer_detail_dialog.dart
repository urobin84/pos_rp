import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/customer_model.dart';
import 'package:pos_rp/providers/transaction_provider.dart';
import 'package:provider/provider.dart';

class CustomerDetailDialog extends StatelessWidget {
  final Customer customer;

  const CustomerDetailDialog({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final customerTransactions =
        transactionProvider.transactions
            .where((tx) => tx.customerName == customer.name)
            .toList();

    final totalSpend = customerTransactions.fold<double>(
      0.0,
      (sum, tx) => sum + tx.totalAmount,
    );

    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 20.0),
          child: Text(
            customer.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ListBody(
              children: <Widget>[
                _buildDetailRow('Email:', customer.email),
                _buildDetailRow('Phone:', customer.phone),
                _buildDetailRow('Address:', customer.address),
                _buildDetailRow(
                  'Date of Birth:',
                  customer.dateOfBirth != null
                      ? DateFormat('d MMM yyyy').format(customer.dateOfBirth!)
                      : 'Not set',
                ),
                _buildDetailRow(
                  'Registration Date:',
                  DateFormat('d MMM yyyy').format(customer.registrationDate),
                ),
                const Divider(height: 30),
                _buildDetailRow(
                  'Total Spend:',
                  priceFormat.format(totalSpend),
                  isBold: true,
                ),
                _buildDetailRow(
                  'Purchase History:',
                  '${customerTransactions.length} transactions',
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                child: const Text('Edit'),
                onPressed: () => Navigator.of(context).pop('edit'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

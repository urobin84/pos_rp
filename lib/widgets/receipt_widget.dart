import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/transaction_model.dart';
import 'package:pos_rp/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class ReceiptWidget extends StatelessWidget {
  final Transaction transaction;

  const ReceiptWidget({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final priceFormat = NumberFormat("#,##0", "id_ID");

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (settings.logoPath != null &&
              File(settings.logoPath!).existsSync())
            Image.file(File(settings.logoPath!), height: 60),
          if (settings.logoPath != null) const SizedBox(height: 16),
          Text(
            settings.name ?? 'Kasir Robin Puspa',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          if (settings.address != null && settings.address!.isNotEmpty)
            Text(
              settings.address!,
              style: const TextStyle(fontSize: 14, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          if (settings.phone != null && settings.phone!.isNotEmpty)
            Text(
              settings.phone!,
              style: const TextStyle(fontSize: 14, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          const Text(
            '--------------------------------',
            style: TextStyle(color: Colors.black),
          ),
          _buildRow(
            'Tanggal',
            DateFormat('dd/MM/yy HH:mm').format(transaction.createdAt),
          ),
          _buildRow('Pelanggan', transaction.customerName),
          _buildRow('Kasir', transaction.cashierName),
          const Text(
            '--------------------------------',
            style: TextStyle(color: Colors.black),
          ),
          for (var item in transaction.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(color: Colors.black),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '  ${item.quantity} x ${priceFormat.format(item.price)}',
                        style: const TextStyle(color: Colors.black),
                      ),
                      Text(
                        priceFormat.format(item.quantity * item.price),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const Text(
            '--------------------------------',
            style: TextStyle(color: Colors.black),
          ),
          _buildRow(
            'Subtotal',
            'Rp ${priceFormat.format(transaction.subtotal)}',
          ),
          if (transaction.discount > 0)
            _buildRow(
              'Diskon',
              'Rp -${priceFormat.format(transaction.discount)}',
            ),
          _buildRow(
            'TOTAL',
            'Rp ${priceFormat.format(transaction.totalAmount)}',
            isTotal: true,
          ),
          const SizedBox(height: 16),
          Text(
            settings.motto ?? 'Terima Kasih!',
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    final style = TextStyle(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      fontSize: isTotal ? 16 : 14,
      color: Colors.black,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

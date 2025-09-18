import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/transaction_model.dart';
import 'package:pos_rp/providers/settings_provider.dart';
import 'package:pos_rp/providers/printer_provider.dart';
import 'package:pos_rp/utils/receipt_generator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

class TransactionDetailDialog extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailDialog({super.key, required this.transaction});

  @override
  State<TransactionDetailDialog> createState() =>
      _TransactionDetailDialogState();
}

class _TransactionDetailDialogState extends State<TransactionDetailDialog> {
  bool _isSharing = false;
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final printerProvider = Provider.of<PrinterProvider>(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 20.0),
          child: const Text(
            'Detail Transaksi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID Transaksi:', widget.transaction.id),
                _buildDetailRow('Pelanggan:', widget.transaction.customerName),
                _buildDetailRow(
                  'Tanggal:',
                  DateFormat(
                    'd MMM yyyy, HH:mm',
                  ).format(widget.transaction.createdAt),
                ),
                _buildDetailRow(
                  'Metode Bayar:',
                  widget.transaction.paymentMethod.toUpperCase(),
                ),
                _buildDetailRow('Kasir:', widget.transaction.cashierName),
                _buildDetailRow('Status:', widget.transaction.status),
                const Divider(height: 20),
                _buildDetailRow(
                  'Subtotal:',
                  priceFormat.format(widget.transaction.subtotal),
                ),
                _buildDetailRow(
                  'Diskon:',
                  '- ${priceFormat.format(widget.transaction.discount)}',
                ),
                if (widget.transaction.additionalCosts > 0)
                  _buildDetailRow(
                    'Biaya Tambahan:',
                    priceFormat.format(widget.transaction.additionalCosts),
                  ),
                const Divider(height: 20),
                Text(
                  'Item Dibeli:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...widget.transaction.items.map((item) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item.productName} (x${item.quantity})'),
                    trailing: Text(
                      priceFormat.format(item.price * item.quantity),
                    ),
                  );
                }).toList(),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      priceFormat.format(widget.transaction.totalAmount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _isPrinting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print),
                onPressed: _isPrinting || !printerProvider.connected
                    ? null
                    : _printReceipt,
                tooltip: 'Cetak Struk',
              ),
              IconButton(
                icon:
                    _isSharing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.share),
                onPressed: _isSharing ? null : _shareReceiptToWhatsApp,
                tooltip: 'Bagikan Struk',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
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

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);

    final printerProvider = Provider.of<PrinterProvider>(context, listen: false);
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    final success = await printerProvider.printTicket(
      widget.transaction,
      settingsProvider,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Struk dikirim ke printer'
              : 'Gagal mencetak, periksa koneksi printer.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    setState(() => _isPrinting = false);
  }

  Future<void> _shareReceiptToWhatsApp() async {
    setState(() => _isSharing = true);

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final receiptText = generateTextReceipt(widget.transaction, settings);
    await Share.share(receiptText, subject: 'Struk Pembelian');

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }
}

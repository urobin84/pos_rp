import 'package:flutter/material.dart';
import 'package:pos_rp/models/transaction_model.dart';
import 'package:pos_rp/providers/settings_provider.dart';
import 'package:pos_rp/providers/printer_provider.dart';
import 'package:pos_rp/widgets/receipt_widget.dart';
import 'package:pos_rp/utils/receipt_generator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptViewDialog extends StatefulWidget {
  final Transaction transaction;

  const ReceiptViewDialog({super.key, required this.transaction});

  @override
  State<ReceiptViewDialog> createState() => _ReceiptViewDialogState();
}

class _ReceiptViewDialogState extends State<ReceiptViewDialog> {
  bool _isSharing = false;
  bool _isPrinting = false;

  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final receiptText = generateTextReceipt(widget.transaction, settings);
    await Share.share(receiptText, subject: 'Struk Pembelian');

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);

    final printerProvider = Provider.of<PrinterProvider>(
      context,
      listen: false,
    );
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

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

  @override
  Widget build(BuildContext context) {
    final printerProvider = Provider.of<PrinterProvider>(context);

    return AlertDialog(
      title: const Text('Transaksi Berhasil'),
      content: SingleChildScrollView(
        // The receipt widget is now just for visual display in the dialog
        child: ReceiptWidget(transaction: widget.transaction),
      ),
      actions: [
        TextButton.icon(
          icon:
              _isPrinting
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.print),
          label: const Text('Cetak'),
          onPressed:
              _isPrinting || !printerProvider.connected ? null : _printReceipt,
        ),
        TextButton.icon(
          icon:
              _isSharing
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.share),
          label: const Text('Bagikan'),
          onPressed: _isSharing ? null : _shareReceipt,
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

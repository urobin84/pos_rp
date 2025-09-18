import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/transaction_model.dart';
import 'package:pos_rp/providers/settings_provider.dart';
import 'package:pos_rp/widgets/receipt_view_dialog.dart';
import 'package:provider/provider.dart';

/// Shows a custom-themed dialog.
Future<void> showCharmingModal(
  BuildContext context, {
  required String title,
  required String message,
  Transaction? transaction,
}) {
  return showDialog(
    context: context,
    builder:
        (ctx) => CharmingModal(
          title: title,
          message: message,
          transaction: transaction,
        ),
  );
}

/// A custom-themed modal dialog with a green, charming aesthetic.
class CharmingModal extends StatelessWidget {
  final String title;
  final Transaction? transaction;
  final String message;
  final IconData icon;
  final Color iconColor;

  const CharmingModal({
    super.key,
    required this.title,
    required this.message,
    this.transaction,
    this.icon = Icons.check_circle,
    this.iconColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Icon(icon, color: iconColor, size: 64),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (transaction != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Transaksi berhasil dicatat oleh:',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${transaction!.cashierName} di ${settings.name ?? 'Toko Anda'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat(
                'd MMMM yyyy, HH:mm:ss',
              ).format(transaction!.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Text('Selamat! 🎉', style: theme.textTheme.titleMedium),
          ],
        ],
      ),
      actions: [
        Center(
          child:
              transaction != null
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the modal
                          showDialog(
                            context: context,
                            builder:
                                (ctx) => ReceiptViewDialog(
                                  transaction: transaction!,
                                ),
                          );
                        },
                        child: const Text('LIHAT STRUK'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('SELESAI'),
                      ),
                    ],
                  )
                  : TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
        ),
      ],
      actionsPadding: const EdgeInsets.only(bottom: 20.0),
    );
  }
}

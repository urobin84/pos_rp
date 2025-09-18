import 'package:intl/intl.dart';
import 'package:pos_rp/models/transaction_model.dart';
import 'package:pos_rp/providers/settings_provider.dart';

/// Generates a plain text receipt string for a given transaction.
///
/// This is useful for sharing via text-based apps like WhatsApp.
String generateTextReceipt(Transaction transaction, SettingsProvider settings) {
  final priceFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final dateFormat = DateFormat('d MMM yyyy, HH:mm');

  final buffer = StringBuffer();
  buffer.writeln('*${settings.name ?? 'Kasir Robin Puspa'}*');
  if (settings.address != null && settings.address!.isNotEmpty) {
    buffer.writeln(settings.address);
  }
  if (settings.phone != null && settings.phone!.isNotEmpty) {
    buffer.writeln(settings.phone);
  }
  buffer.writeln('--------------------------------');
  buffer.writeln('Tanggal: ${dateFormat.format(transaction.createdAt)}');
  buffer.writeln('Pelanggan: ${transaction.customerName}');
  buffer.writeln('Kasir: ${transaction.cashierName}');
  buffer.writeln('--------------------------------');

  for (final item in transaction.items) {
    buffer.writeln('${item.productName}');
    buffer.writeln(
      '  ${item.quantity} x ${priceFormat.format(item.price)} = ${priceFormat.format(item.quantity * item.price)}',
    );
  }

  buffer.writeln('--------------------------------');
  buffer.writeln('Subtotal: ${priceFormat.format(transaction.subtotal)}');
  buffer.writeln('Diskon: - ${priceFormat.format(transaction.discount)}');
  if (transaction.additionalCosts > 0) {
    buffer.writeln(
      'Biaya Tambahan: ${priceFormat.format(transaction.additionalCosts)}',
    );
  }
  buffer.writeln('--------------------------------');
  buffer.writeln('*TOTAL: ${priceFormat.format(transaction.totalAmount)}*');
  buffer.writeln();
  buffer.writeln(settings.motto ?? 'Terima Kasih!');

  return buffer.toString();
}

import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:pos_rp/models/transaction_model.dart';
import 'package:pos_rp/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterProvider with ChangeNotifier {
  bool _connected = false;
  List<BluetoothInfo> _availableDevices = [];
  String? _savedMacAddress;
  String? _connectedMacAddress;

  bool get connected => _connected;
  List<BluetoothInfo> get availableDevices => _availableDevices;
  String? get connectedMacAddress => _connectedMacAddress;

  PrinterProvider() {
    _loadSavedPrinter();
    _checkConnectionStatus();
  }

  Future<void> _loadSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    _savedMacAddress = prefs.getString('saved_printer_mac');
    if (_savedMacAddress != null) {
      await connectToDeviceByMac(_savedMacAddress!);
    }
  }

  Future<void> _checkConnectionStatus() async {
    _connected = await PrintBluetoothThermal.connectionStatus;
    notifyListeners();
  }

  Future<void> getBluetooths() async {
    _availableDevices = await PrintBluetoothThermal.pairedBluetooths;
    notifyListeners();
  }

  Future<bool> connectToDevice(BluetoothInfo device) async {
    _connected = await PrintBluetoothThermal.connect(
      macPrinterAddress: device.macAdress,
    );
    if (_connected) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_printer_mac', device.macAdress);
      _savedMacAddress = device.macAdress;
      _connectedMacAddress = device.macAdress;
    } else {
      _connectedMacAddress = null;
    }
    notifyListeners();
    return _connected;
  }

  Future<bool> connectToDeviceByMac(String mac) async {
    _connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (_connected) {
      _connectedMacAddress = mac;
    } else {
      _connectedMacAddress = null;
    }
    notifyListeners();
    return _connected;
  }

  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
    _connected = false;
    _connectedMacAddress = null;
    notifyListeners();
  }

  Future<bool> printTicket(
    Transaction transaction,
    SettingsProvider settings,
  ) async {
    if (!_connected) {
      // Attempt to reconnect to the saved printer if not connected
      if (_savedMacAddress != null) {
        final reconnected = await connectToDeviceByMac(_savedMacAddress!);
        if (!reconnected) return false;
      } else {
        return false;
      }
    }

    List<int> bytes = await _generateTicketBytes(transaction, settings);
    final result = await PrintBluetoothThermal.writeBytes(bytes);
    return result;
  }

  Future<bool> printTestTicket(SettingsProvider settings) async {
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      List<int> ticket = await _generateTestTicketBytes(settings);
      final result = await PrintBluetoothThermal.writeBytes(ticket);
      return result;
    } else {
      // Not connected
      return false;
    }
  }

  Future<List<int>> _generateTestTicketBytes(SettingsProvider settings) async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.reset();

    // Enable double-strike mode for bolder text using raw ESC/POS command
    bytes += generator.rawBytes([27, 71, 1]); // ESC G 1

    // Load, decode, and resize logo
    final img.Image? logo = await _getResizedLogo(settings);
    if (logo != null) {
      bytes += generator.image(logo);
    }

    bytes += generator.text(
      'Test Print',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.text('Bold text', styles: const PosStyles(bold: true));
    bytes += generator.text(
      'Reverse text',
      styles: const PosStyles(reverse: true),
    );
    bytes += generator.text(
      'Underlined text',
      styles: const PosStyles(underline: true),
      linesAfter: 1,
    );
    bytes += generator.text(
      'Align left',
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      'Align center',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Align right',
      styles: const PosStyles(align: PosAlign.right),
      linesAfter: 1,
    );

    bytes += generator.row([
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center),
      ),
      PosColumn(
        text: 'col6',
        width: 6,
        styles: const PosStyles(align: PosAlign.center),
      ),
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center),
      ),
    ]);

    // Barcode
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    bytes += generator.barcode(Barcode.upcA(barData));

    // QR code
    bytes += generator.qrcode('https://github.com/robin-puspa/pos_rp');

    // Disable double-strike mode using raw ESC/POS command
    bytes += generator.rawBytes([27, 71, 0]); // ESC G 0

    bytes += generator.feed(0);
    bytes += generator.cut();
    return bytes;
  }

  Future<List<int>> _generateTicketBytes(
    Transaction transaction,
    SettingsProvider settings,
  ) async {
    // Using default profile for wider compatibility
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Enable double-strike mode for bolder text using raw ESC/POS command
    bytes += generator.rawBytes([27, 71, 1]); // ESC G 1

    // Reusable currency formatters
    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '', // No symbol for item totals
      decimalDigits: 0,
    );
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ', // With symbol for summary
      decimalDigits: 0,
    );

    // Load, decode, and resize logo
    final img.Image? logo = await _getResizedLogo(settings);
    if (logo != null) {
      bytes += generator.image(logo);
      bytes += generator.feed(1); // Add space after logo
    }

    // Shop details
    bytes += generator.text(
      settings.name ?? 'Kasir RP',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      settings.address ?? '',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      settings.phone ?? '',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();

    // Transaction details
    bytes += generator.row([
      PosColumn(text: 'Kasir:', width: 3),
      PosColumn(
        text: transaction.cashierName,
        width: 9,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Pelanggan:', width: 4),
      PosColumn(
        text: transaction.customerName,
        width: 8,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Tanggal:', width: 4),
      PosColumn(
        text: DateFormat('dd/MM/yy HH:mm').format(transaction.createdAt),
        width: 8,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.hr();

    // Items
    // Using a two-line format for each item for better readability
    for (var item in transaction.items) {
      // Line 1: Product Name
      bytes += generator.text(
        item.productName,
        styles: const PosStyles(align: PosAlign.left),
      );

      // Line 2: Qty x Price = Total (indented)
      final itemPrice = priceFormat.format(item.price);
      final itemTotal = priceFormat.format(item.price * item.quantity);
      bytes += generator.row([
        PosColumn(
          text: '  ${item.quantity} x $itemPrice',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: itemTotal,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += generator.hr();

    // Totals
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6),
      PosColumn(
        text: currencyFormat.format(transaction.subtotal),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Diskon', width: 6),
      PosColumn(
        text: currencyFormat.format(transaction.discount),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Total', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: currencyFormat.format(transaction.totalAmount),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    bytes += generator.hr();

    bytes += generator.feed(1); // Add space before footer
    // Footer
    bytes += generator.text(
      settings.motto ?? 'Terima kasih!',
      styles: const PosStyles(align: PosAlign.center),
    );

    // Disable double-strike mode before cutting using raw ESC/POS command
    bytes += generator.rawBytes([27, 71, 0]); // ESC G 0
    bytes += generator.feed(0);
    bytes += generator.cut();

    return bytes;
  }

  /// Loads the logo from settings or assets, decodes, and resizes it.
  Future<img.Image?> _getResizedLogo(SettingsProvider settings) async {
    Uint8List? logoBytes;

    // Try to load custom logo first
    if (settings.logoPath != null && settings.logoPath!.isNotEmpty) {
      final file = File(settings.logoPath!);
      if (await file.exists()) {
        logoBytes = await file.readAsBytes();
      }
    }

    // If no custom logo, load the default asset
    if (logoBytes == null) {
      final ByteData data = await rootBundle.load('assets/images/icon.png');
      logoBytes = data.buffer.asUint8List();
    }

    final img.Image? logo = img.decodeImage(logoBytes);

    if (logo != null) {
      // For 58mm printers, the max width is typically 384 dots.
      // We resize the image to 45% of the width to leave some margin.
      const int maxWidth = 173; // 384 * 0.45
      return img.copyResize(logo, width: maxWidth);
    }

    return null;
  }
}

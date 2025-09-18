import 'package:flutter/material.dart';
import 'package:pos_rp/providers/printer_provider.dart';
import 'package:pos_rp/providers/settings_provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:provider/provider.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  bool _isScanning = false;
  String? _connectingMac;
  bool _isTestPrinting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanForPrinters();
    });
  }

  Future<void> _scanForPrinters() async {
    setState(() {
      _isScanning = true;
    });

    // This getter will also request the permission if it's not granted.
    final hasPermission =
        await PrintBluetoothThermal.isPermissionBluetoothGranted;

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth permission is required to find printers.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isScanning = false);
      }
      return;
    }

    try {
      await Provider.of<PrinterProvider>(
        context,
        listen: false,
      ).getBluetooths();
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _connect(BluetoothInfo printer) async {
    setState(() {
      _connectingMac = printer.macAdress;
    });
    final provider = Provider.of<PrinterProvider>(context, listen: false);
    final success = await provider.connectToDevice(printer);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Connected to ${printer.name}' : 'Failed to connect',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      setState(() {
        _connectingMac = null;
      });
    }
  }

  Future<void> _runTestPrint() async {
    setState(() {
      _isTestPrinting = true;
    });

    final provider = Provider.of<PrinterProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final success = await provider.printTestTicket(settings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Test print sent successfully!' : 'Test print failed.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      setState(() {
        _isTestPrinting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final printerProvider = Provider.of<PrinterProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _scanForPrinters,
              tooltip: 'Scan for Printers',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: printerProvider.availableDevices.length,
              itemBuilder: (ctx, i) {
                final device = printerProvider.availableDevices[i];
                final isConnecting = _connectingMac == device.macAdress;
                final isConnected =
                    printerProvider.connected &&
                    printerProvider.connectedMacAddress == device.macAdress;

                return ListTile(
                  leading: const Icon(Icons.print_outlined),
                  title: Text(device.name),
                  subtitle: Text(device.macAdress),
                  trailing:
                      isConnecting
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                          : (isConnected
                              ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                              : null),
                  onTap:
                      isConnecting || isConnected
                          ? null
                          : () => _connect(device),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon:
                    _isTestPrinting
                        ? const SizedBox.shrink()
                        : const Icon(Icons.receipt_long),
                label:
                    _isTestPrinting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                        : const Text('Test Print'),
                onPressed:
                    printerProvider.connected && !_isTestPrinting
                        ? _runTestPrint
                        : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

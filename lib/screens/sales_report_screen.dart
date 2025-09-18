import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/product_model.dart';
import 'package:pos_rp/models/transaction_model.dart';
import 'package:pos_rp/providers/product_provider.dart';
import 'package:pos_rp/providers/transaction_provider.dart';
import 'package:provider/provider.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Default to this month
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (newDateRange != null) {
      setState(() {
        _selectedDateRange = newDateRange;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final filteredTransactions =
        transactionProvider.transactions.where((tx) {
          if (_selectedDateRange == null) return true;
          final txDate = tx.createdAt;
          final startDate = _selectedDateRange!.start;
          // Add 1 day to end date to include the whole day
          final endDate = _selectedDateRange!.end.add(const Duration(days: 1));
          return txDate.isAfter(startDate) && txDate.isBefore(endDate);
        }).toList();

    // --- Data Calculations ---
    final grossSales = filteredTransactions.fold(
      0.0,
      (sum, tx) => sum + tx.subtotal,
    );
    final totalDiscounts = filteredTransactions.fold(
      0.0,
      (sum, tx) => sum + tx.discount,
    );
    final netSales = grossSales - totalDiscounts;

    // Sales per product
    final productSales = <String, int>{};
    for (final tx in filteredTransactions) {
      for (final item in tx.items) {
        productSales.update(
          item.productId,
          (value) => value + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }
    final sortedProductSales =
        productSales.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Sales per cashier
    final cashierSales = <String, double>{};
    for (final tx in filteredTransactions) {
      cashierSales.update(
        tx.cashierName,
        (value) => value + tx.totalAmount,
        ifAbsent: () => tx.totalAmount,
      );
    }
    final sortedCashierSales =
        cashierSales.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
            tooltip: 'Pilih Rentang Tanggal',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDateRangeDisplay(),
          _buildSummaryCard('Penjualan Kotor', priceFormat.format(grossSales)),
          _buildSummaryCard('Total Diskon', priceFormat.format(totalDiscounts)),
          _buildSummaryCard(
            'Penjualan Bersih',
            priceFormat.format(netSales),
            isHighlighted: true,
          ),
          const Divider(height: 30),
          _buildSectionTitle('Produk Terlaris'),
          _buildProductSalesList(sortedProductSales, productProvider),
          const Divider(height: 30),
          _buildSectionTitle('Penjualan per Kasir'),
          _buildCashierSalesList(sortedCashierSales, priceFormat),
        ],
      ),
    );
  }

  Widget _buildDateRangeDisplay() {
    final start = DateFormat(
      'd MMM yyyy',
    ).format(_selectedDateRange?.start ?? DateTime.now());
    final end = DateFormat(
      'd MMM yyyy',
    ).format(_selectedDateRange?.end ?? DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        'Menampilkan data dari $start hingga $end',
        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value, {
    bool isHighlighted = false,
  }) {
    return Card(
      elevation: isHighlighted ? 4 : 2,
      color: isHighlighted ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.green.shade800 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildProductSalesList(
    List<MapEntry<String, int>> sales,
    ProductProvider provider,
  ) {
    if (sales.isEmpty) {
      return const Text('Tidak ada data penjualan produk.');
    }
    return Column(
      children:
          sales.take(5).map((entry) {
            Product? product;
            try {
              product = provider.findById(entry.key);
            } catch (e) {
              // Product might be deleted
            }
            return ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(product?.name ?? 'Produk Dihapus'),
              trailing: Text('${entry.value} terjual'),
            );
          }).toList(),
    );
  }

  Widget _buildCashierSalesList(
    List<MapEntry<String, double>> sales,
    NumberFormat format,
  ) {
    if (sales.isEmpty) {
      return const Text('Tidak ada data penjualan kasir.');
    }
    return Column(
      children:
          sales.map((entry) {
            return ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(entry.key),
              trailing: Text(format.format(entry.value)),
            );
          }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/product_model.dart';
import 'package:pos_rp/providers/product_provider.dart';
import 'package:pos_rp/providers/transaction_provider.dart';
import 'package:provider/provider.dart';

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Default to this month for stock movement calculation
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
    final productProvider = Provider.of<ProductProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final products = productProvider.products;
    final theme = Theme.of(context);

    // --- Data Calculations ---

    // Filter transactions for the selected date range to calculate units sold
    final filteredTransactions =
        transactionProvider.transactions.where((tx) {
          if (_selectedDateRange == null) return true;
          final txDate = tx.createdAt;
          final startDate = _selectedDateRange!.start;
          // Add 1 day to end date to include the whole day
          final endDate = _selectedDateRange!.end.add(const Duration(days: 1));
          return txDate.isAfter(startDate) && txDate.isBefore(endDate);
        }).toList();

    // Calculate units sold per product
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

    // Calculate summary metrics
    double totalInventoryValueCost = 0;
    double totalInventoryValueRetail = 0;
    int lowStockItemsCount = 0;

    for (final product in products) {
      totalInventoryValueCost += product.stock * product.costPrice;
      totalInventoryValueRetail += product.stock * product.price;
      if (product.stock <= product.minStockLevel) {
        lowStockItemsCount++;
      }
    }
    final potentialProfit = totalInventoryValueRetail - totalInventoryValueCost;

    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Inventaris'),
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
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            children: [
              _buildSummaryCard(
                'Nilai Stok (Modal)',
                priceFormat.format(totalInventoryValueCost),
                Icons.attach_money,
              ),
              _buildSummaryCard(
                'Nilai Stok (Jual)',
                priceFormat.format(totalInventoryValueRetail),
                Icons.point_of_sale,
              ),
              _buildSummaryCard(
                'Potensi Profit',
                priceFormat.format(potentialProfit),
                Icons.trending_up,
              ),
              _buildSummaryCard(
                'Stok Menipis',
                '$lowStockItemsCount Produk',
                Icons.warning_amber_rounded,
                valueColor:
                    lowStockItemsCount > 0 ? Colors.orange.shade800 : null,
              ),
            ],
          ),
          const Divider(height: 30),
          Text('Detail Stok Produk', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          ...products.map((product) {
            final unitsSold = productSales[product.id] ?? 0;
            final isLowStock = product.stock <= product.minStockLevel;
            return Card(
              color: isLowStock ? Colors.orange.withOpacity(0.1) : null,
              child: ListTile(
                title: Text(product.name),
                subtitle: Text(
                  'Terjual: $unitsSold | Modal: ${priceFormat.format(product.costPrice)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Sisa: ${product.stock}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isLowStock ? Colors.orange.shade900 : null,
                      ),
                    ),
                    Text(priceFormat.format(product.price)),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDateRangeDisplay() {
    final start = DateFormat('d MMM yyyy').format(_selectedDateRange!.start);
    final end = DateFormat('d MMM yyyy').format(_selectedDateRange!.end);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        'Pergerakan stok dari $start hingga $end',
        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(height: 4),
              Text(title, style: theme.textTheme.bodySmall),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

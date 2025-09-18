import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/providers/expense_provider.dart';
import 'package:pos_rp/providers/purchase_provider.dart';
import 'package:pos_rp/providers/transaction_provider.dart';
import 'package:provider/provider.dart';

class CashFlowReportScreen extends StatefulWidget {
  const CashFlowReportScreen({super.key});

  @override
  State<CashFlowReportScreen> createState() => _CashFlowReportScreenState();
}

class _CashFlowReportScreenState extends State<CashFlowReportScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
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
    final purchaseProvider = Provider.of<PurchaseProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // --- Data Calculations ---
    final endDate = _selectedDateRange!.end.add(const Duration(days: 1));

    // Cash Inflows
    final sales =
        transactionProvider.transactions
            .where(
              (tx) =>
                  tx.createdAt.isAfter(_selectedDateRange!.start) &&
                  tx.createdAt.isBefore(endDate),
            )
            .toList();
    final cashSales = sales
        .where((tx) => tx.paymentMethod == 'cash')
        .fold(0.0, (sum, tx) => sum + tx.totalAmount);
    final transferSales = sales
        .where((tx) => tx.paymentMethod == 'transfer')
        .fold(0.0, (sum, tx) => sum + tx.totalAmount);
    final totalInflow = cashSales + transferSales;

    // Cash Outflows
    final purchases =
        purchaseProvider.purchases
            .where(
              (p) =>
                  p.purchaseDate.isAfter(_selectedDateRange!.start) &&
                  p.purchaseDate.isBefore(endDate),
            )
            .toList();
    final expenses =
        expenseProvider.expenses
            .where(
              (e) =>
                  e.date.isAfter(_selectedDateRange!.start) &&
                  e.date.isBefore(endDate),
            )
            .toList();
    final purchaseCosts = purchases.fold(0.0, (sum, p) => sum + p.totalCost);
    final operationalCosts = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalOutflow = purchaseCosts + operationalCosts;

    // Net Cash Flow
    final netCashFlow = totalInflow - totalOutflow;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Arus Kas'),
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
          _buildSectionTitle('Arus Kas Masuk (Inflow)'),
          _buildSummaryCard(
            'Penjualan Tunai',
            priceFormat.format(cashSales),
            Colors.green,
          ),
          _buildSummaryCard(
            'Penjualan Transfer',
            priceFormat.format(transferSales),
            Colors.blue,
          ),
          _buildSummaryCard(
            'Total Kas Masuk',
            priceFormat.format(totalInflow),
            Theme.of(context).colorScheme.primary,
            isHighlighted: true,
          ),
          const Divider(height: 30),
          _buildSectionTitle('Arus Kas Keluar (Outflow)'),
          _buildSummaryCard(
            'Pembelian Inventaris',
            priceFormat.format(purchaseCosts),
            Colors.orange,
          ),
          _buildSummaryCard(
            'Biaya Operasional',
            priceFormat.format(operationalCosts),
            Colors.red,
          ),
          _buildSummaryCard(
            'Total Kas Keluar',
            priceFormat.format(totalOutflow),
            Colors.red.shade700,
            isHighlighted: true,
          ),
          const Divider(height: 30),
          _buildSectionTitle('Arus Kas Bersih (Net)'),
          _buildSummaryCard(
            'Total Inflow - Total Outflow',
            priceFormat.format(netCashFlow),
            netCashFlow >= 0 ? Colors.green.shade800 : Colors.red.shade900,
            isHighlighted: true,
            isLarge: true,
          ),
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
        'Menampilkan data dari $start hingga $end',
        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color, {
    bool isHighlighted = false,
    bool isLarge = false,
  }) {
    return Card(
      elevation: isHighlighted ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style:
                    isLarge
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              value,
              style: (isLarge
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

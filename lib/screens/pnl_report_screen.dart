import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/providers/expense_provider.dart';
import 'package:pos_rp/providers/purchase_provider.dart';
import 'package:pos_rp/providers/transaction_provider.dart';
import 'package:provider/provider.dart';

class PnlReportScreen extends StatefulWidget {
  const PnlReportScreen({super.key});

  @override
  State<PnlReportScreen> createState() => _PnlReportScreenState();
}

class _PnlReportScreenState extends State<PnlReportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  double _totalSales = 0;
  double _totalCogs = 0; // Cost of Goods Sold (HPP)
  double _grossProfit = 0;
  double _totalExpenses = 0;
  double _netProfit = 0;

  bool _isLoading = false;

  final _priceFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateReport();
    });
  }

  void _calculateReport() {
    if (_startDate == null || _endDate == null) return;

    setState(() => _isLoading = true);

    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final purchaseProvider = Provider.of<PurchaseProvider>(
      context,
      listen: false,
    );
    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );

    // Calculate Total Sales
    _totalSales = transactionProvider.transactions
        .where(
          (tx) =>
              tx.createdAt.isAfter(_startDate!) &&
              tx.createdAt.isBefore(_endDate!.add(const Duration(days: 1))),
        )
        .fold(0.0, (sum, tx) => sum + tx.totalAmount);

    // Calculate Total COGS (using purchases as an estimate)
    _totalCogs = purchaseProvider.purchases
        .where(
          (p) =>
              p.purchaseDate.isAfter(_startDate!) &&
              p.purchaseDate.isBefore(_endDate!.add(const Duration(days: 1))),
        )
        .fold(0.0, (sum, p) => sum + p.totalCost);

    // Calculate Total Expenses
    _totalExpenses = expenseProvider.expenses
        .where(
          (e) =>
              e.date.isAfter(_startDate!) &&
              e.date.isBefore(_endDate!.add(const Duration(days: 1))),
        )
        .fold(0.0, (sum, e) => sum + e.amount);

    _grossProfit = _totalSales - _totalCogs;
    _netProfit = _grossProfit - _totalExpenses;

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Laba & Rugi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildDateFilterButton(context, isStartDate: true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDateFilterButton(context, isStartDate: false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        _buildSummaryCard(
                          children: [
                            _buildSummaryRow('Total Penjualan', _totalSales),
                            _buildSummaryRow(
                              'Total HPP (Pembelian)',
                              -_totalCogs,
                            ),
                          ],
                          footer: _buildSummaryRow(
                            'Laba Kotor',
                            _grossProfit,
                            isBold: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryCard(
                          children: [
                            _buildSummaryRow(
                              'Total Biaya Operasional',
                              -_totalExpenses,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryCard(
                          color:
                              _netProfit >= 0
                                  ? Colors.green[100]
                                  : Colors.red[100],
                          footer: _buildSummaryRow(
                            'Laba Bersih',
                            _netProfit,
                            isBold: true,
                            valueColor:
                                _netProfit >= 0
                                    ? Colors.green[800]
                                    : Colors.red[800],
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    double value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _priceFormat.format(value),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    List<Widget>? children,
    Widget? footer,
    Color? color,
  }) {
    return Card(
      color: color,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (children != null) ...children,
            if (children != null && footer != null) const Divider(height: 20),
            if (footer != null) footer,
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterButton(
    BuildContext context, {
    required bool isStartDate,
  }) {
    final date = isStartDate ? _startDate : _endDate;
    final text =
        date == null
            ? (isStartDate ? 'Tanggal Mulai' : 'Tanggal Akhir')
            : DateFormat('d MMM y').format(date);

    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: () async {
        final now = DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: DateTime(2000),
          lastDate: now,
        );
        if (pickedDate != null) {
          setState(() {
            if (isStartDate) {
              _startDate = pickedDate;
            } else {
              _endDate = pickedDate;
            }
          });
          _calculateReport();
        }
      },
    );
  }
}

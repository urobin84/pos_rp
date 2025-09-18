import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/transaction_model.dart';
import 'package:pos_rp/providers/transaction_provider.dart';
import 'package:pos_rp/widgets/transaction_detail_dialog.dart';
import 'package:pos_rp/widgets/sized_alert_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  // Pagination and filtering state
  final _scrollController = ScrollController();
  List<Transaction> _allFilteredTransactions = [];
  List<Transaction> _displayedTransactions = [];
  bool _isLoading = true; // For initial filter/load
  bool _isPaginating = false; // For loading next page
  final int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // Debounce could be useful here in a real app
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _applyFilters();
      }
    });
    _scrollController.addListener(_scrollListener);

    // Initial data load after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // If we are at the bottom of the list, load more
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  void _applyFilters() {
    setState(() {
      _isLoading = true;
    });

    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final allTransactions = transactionProvider.transactions;

    _allFilteredTransactions = _getFilteredTransactions(allTransactions);

    // Reset displayed list and load the first page
    _displayedTransactions = [];
    _loadNextPage();

    setState(() {
      _isLoading = false;
    });
  }

  void _loadNextPage() {
    if (_isPaginating ||
        _displayedTransactions.length == _allFilteredTransactions.length) {
      return; // Already loading or no more items
    }

    setState(() {
      _isPaginating = true;
    });

    // Simulate a network delay for loading, otherwise it's too fast to see
    Future.delayed(const Duration(milliseconds: 500), () {
      final currentLength = _displayedTransactions.length;
      final remaining = _allFilteredTransactions.length - currentLength;
      final nextPageSize = remaining > _pageSize ? _pageSize : remaining;

      if (nextPageSize > 0) {
        _displayedTransactions.addAll(
          _allFilteredTransactions.sublist(
            currentLength,
            currentLength + nextPageSize,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _isPaginating = false;
        });
      }
    });
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    return transactions.where((tx) {
      final query = _searchQuery.toLowerCase();
      final customerMatch = tx.customerName.toLowerCase().contains(query);
      final productMatch = tx.items.any(
        (item) => item.productName.toLowerCase().contains(query),
      );

      // Date filtering logic
      final createdAtDate = DateTime(
        tx.createdAt.year,
        tx.createdAt.month,
        tx.createdAt.day,
      );
      final startDateMatch =
          _startDate == null ||
          createdAtDate.isAtSameMomentAs(_startDate!) ||
          createdAtDate.isAfter(_startDate!);
      final endDateMatch =
          _endDate == null ||
          createdAtDate.isAtSameMomentAs(_endDate!) ||
          createdAtDate.isBefore(_endDate!);

      return (customerMatch || productMatch) && startDateMatch && endDateMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari (nama pelanggan/produk)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateFilterButton(context, isStartDate: true),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateFilterButton(
                        context,
                        isStartDate: false,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear_all),
                      tooltip: 'Hapus Filter Tanggal',
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? _buildShimmerLoading()
              : _allFilteredTransactions.isEmpty
              ? const Center(child: Text('Tidak ada transaksi yang cocok.'))
              : ListView.builder(
                controller: _scrollController,
                itemCount:
                    _displayedTransactions.length + (_isPaginating ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == _displayedTransactions.length) {
                    return _buildPaginationShimmer();
                  }
                  final tx = _displayedTransactions[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 4,
                    ),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 5.0,
                          ),
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (dCtx) => SizedAlertDialog(
                                  child: TransactionDetailDialog(
                                    transaction: tx,
                                  ),
                                ),
                          );
                        },
                        leading: CircleAvatar(
                          child: Icon(
                            tx.paymentMethod == 'cash'
                                ? Icons.money
                                : Icons.credit_card,
                          ),
                        ),
                        title: Text(tx.customerName),
                        subtitle: Text(
                          DateFormat('d MMM yyyy, HH:mm').format(tx.createdAt),
                        ),
                        trailing: Text(
                          priceFormat.format(tx.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildDateFilterButton(
    BuildContext context, {
    required bool isStartDate,
  }) {
    final text =
        isStartDate
            ? (_startDate == null
                ? 'Tanggal Mulai'
                : DateFormat('d MMM y').format(_startDate!))
            : (_endDate == null
                ? 'Tanggal Akhir'
                : DateFormat('d MMM y').format(_endDate!));

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
          initialDate: (isStartDate ? _startDate : _endDate) ?? now,
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
          _applyFilters();
        }
      },
    );
  }

  Widget _buildShimmerLoading() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: List.generate(10, (i) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 5.0,
                    ),
                  ),
                ),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.white),
                  title: Container(
                    width: 150.0,
                    height: 16.0,
                    color: Colors.white,
                  ),
                  subtitle: Container(
                    width: 100.0,
                    height: 12.0,
                    color: Colors.white,
                  ),
                  trailing: Container(
                    width: 80.0,
                    height: 16.0,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPaginationShimmer() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(10, (i) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 5.0,
                  ),
                ),
              ),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.white),
                title: Container(
                  width: 150.0,
                  height: 16.0,
                  color: Colors.white,
                ),
                subtitle: Container(
                  width: 100.0,
                  height: 12.0,
                  color: Colors.white,
                ),
                trailing: Container(
                  width: 80.0,
                  height: 16.0,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

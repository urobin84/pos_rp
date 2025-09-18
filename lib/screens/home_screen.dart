import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/providers/product_provider.dart';
import 'package:pos_rp/providers/transaction_provider.dart';
import 'package:pos_rp/models/product_model.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showShimmer = true;

  @override
  void initState() {
    super.initState();
    // Ensure shimmer is shown for at least 1 second for a smooth UX.
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showShimmer = false;
        });
      }
    });
  }

  Future<void> _refreshData() async {
    // This function will be called when the user pulls to refresh.
    // We'll call the data fetching methods from our providers.
    // NOTE: I'm assuming your providers have methods named `fetchAndSetProducts`
    // and `fetchAndSetTransactions`. If your method names are different,
    // please replace them here.
    await Future.wait([
      Provider.of<ProductProvider>(context, listen: false).fetchProducts(),
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).fetchTransactions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    // Show shimmer while initial data is loading or for the initial 1-second delay.
    final isStillLoading =
        productProvider.isLoading && transactionProvider.transactions.isEmpty;
    if (_showShimmer || isStillLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
            ),
          ],
        ),
        body: _buildShimmerEffect(),
      );
    }
    // --- Data Calculations ---

    // Sales Summary
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayTransactions =
        transactionProvider.transactions
            .where((tx) => tx.createdAt.isAfter(todayStart))
            .toList();
    final totalSalesToday = todayTransactions.fold<double>(
      0.0,
      (sum, tx) => sum + tx.totalAmount,
    );
    final transactionCountToday = todayTransactions.length;

    // Best Selling Products
    final productSales = <String, int>{};
    for (final tx in transactionProvider.transactions) {
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
    final bestSellers =
        sortedProductSales
            .take(4)
            .map((entry) {
              try {
                final product = productProvider.products.firstWhere(
                  (p) => p.id == entry.key,
                );
                return {'product': product, 'sales': entry.value};
              } catch (e) {
                return null; // Product might have been deleted
              }
            })
            .whereType<Map<String, dynamic>>()
            .toList();

    // Top Customers
    final customerTransactions = <String, int>{};
    for (final tx in transactionProvider.transactions) {
      if (tx.customerName != 'Walk-in Customer') {
        customerTransactions.update(
          tx.customerName,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final topCustomers =
        customerTransactions.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Sales Summary Card
            Card(
              elevation: 4,
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Penjualan Hari Ini',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      // Dummy data for sales
                      Text(
                        'Total Penjualan',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(totalSalesToday),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Text('Jumlah Transaksi: $transactionCountToday'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Best Selling Products
            Text(
              'Produk Terlaris',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: bestSellers.length,
              itemBuilder: (ctx, i) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (bestSellers[i]['product'] as Product).name,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${bestSellers[i]['sales']} terjual',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Top Customers
            Text(
              'Pelanggan Teratas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topCustomers.take(3).length,
              itemBuilder: (ctx, i) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(topCustomers[i].key[0])),
                    title: Text(
                      topCustomers[i].key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '${topCustomers[i].value} transaksi',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sales Summary Shimmer
          Card(
            elevation: 4,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 200, height: 24, color: Colors.white),
                    const SizedBox(height: 16),
                    Container(width: 120, height: 16, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(width: 180, height: 36, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 150, height: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Best Selling Shimmer
          Container(width: 150, height: 24, color: Colors.white),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 4,
            itemBuilder: (ctx, i) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 100, height: 18, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 14, color: Colors.white),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Top Customers Shimmer
          Container(width: 180, height: 24, color: Colors.white),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (ctx, i) {
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.white),
                  title: Container(width: 150, height: 16, color: Colors.white),
                  trailing: Container(
                    width: 100,
                    height: 14,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

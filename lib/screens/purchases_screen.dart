import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/purchase_model.dart';
import 'package:pos_rp/providers/purchase_provider.dart';
import 'package:pos_rp/screens/new_purchase_screen.dart';
import 'package:pos_rp/screens/suppliers_screen.dart';
import 'package:provider/provider.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final purchaseProvider = Provider.of<PurchaseProvider>(context);
    final purchases = purchaseProvider.purchases;
    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pembelian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const SuppliersScreen()),
                ),
            tooltip: 'Kelola Supplier',
          ),
        ],
      ),
      body:
          purchaseProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : purchases.isEmpty
              ? const Center(
                child: Text(
                  'Belum ada data pembelian.',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: purchases.length,
                itemBuilder: (ctx, i) {
                  final purchase = purchases[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          Icons.shopping_cart_checkout,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        'Pembelian dari ${purchase.supplierName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat(
                          'd MMM yyyy, HH:mm',
                        ).format(purchase.purchaseDate),
                      ),
                      trailing: Text(
                        priceFormat.format(purchase.totalCost),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        // TODO: Show purchase detail dialog
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const NewPurchaseScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Catat Pembelian'),
      ),
    );
  }
}

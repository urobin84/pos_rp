import 'package:flutter/material.dart';
import 'package:pos_rp/models/supplier_model.dart';
import 'package:pos_rp/providers/supplier_provider.dart';
import 'package:pos_rp/services/supplier_form_dialog.dart';
import 'package:pos_rp/widgets/sized_alert_dialog.dart';
import 'package:provider/provider.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supplierProvider = Provider.of<SupplierProvider>(context);
    final suppliers = supplierProvider.suppliers;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Supplier')),
      body:
          supplierProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: suppliers.length,
                itemBuilder: (ctx, i) {
                  final supplier = suppliers[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(supplier.name.substring(0, 1)),
                      ),
                      title: Text(supplier.name),
                      subtitle: Text(supplier.phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (ctx) => SizedAlertDialog(
                                  child: SupplierFormDialog(supplier: supplier),
                                ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder:
                (ctx) => const SizedAlertDialog(child: SupplierFormDialog()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

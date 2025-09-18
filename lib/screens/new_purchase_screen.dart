import 'package:flutter/material.dart';
import 'package:pos_rp/models/product_model.dart';
import 'package:pos_rp/models/purchase_item_model.dart';
import 'package:pos_rp/models/purchase_model.dart';
import 'package:pos_rp/models/supplier_model.dart';
import 'package:pos_rp/providers/product_provider.dart';
import 'package:pos_rp/providers/purchase_provider.dart';
import 'package:pos_rp/providers/supplier_provider.dart';
import 'package:pos_rp/widgets/charming_modal.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class NewPurchaseScreen extends StatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  Supplier? _selectedSupplier;
  final List<PurchaseItem> _items = [];
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _costControllers = {};

  void _addProductToPurchase(Product product) {
    if (_items.any((item) => item.productId == product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} sudah ada di daftar.')),
      );
      return;
    }

    setState(() {
      final newItem = PurchaseItem(
        id: const Uuid().v4(),
        purchaseId: '', // Will be set on save
        productId: product.id,
        productName: product.name,
        quantity: 1,
        costPrice: product.costPrice, // Default to current cost price
      );
      _items.add(newItem);
      _qtyControllers[newItem.id] = TextEditingController(text: '1');
      _costControllers[newItem.id] = TextEditingController(
        text: product.costPrice.toStringAsFixed(0),
      );
    });
  }

  void _removeItem(String itemId) {
    setState(() {
      _items.removeWhere((item) => item.id == itemId);
      _qtyControllers.remove(itemId)?.dispose();
      _costControllers.remove(itemId)?.dispose();
    });
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate() || _selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih supplier dan isi semua data item.'),
        ),
      );
      return;
    }

    final purchaseProvider = Provider.of<PurchaseProvider>(
      context,
      listen: false,
    );
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context);

    double totalCost = 0;
    final List<PurchaseItem> finalItems = [];

    for (final item in _items) {
      final qty = int.parse(_qtyControllers[item.id]!.text);
      final cost = double.parse(_costControllers[item.id]!.text);
      totalCost += qty * cost;
      finalItems.add(
        PurchaseItem(
          id: item.id,
          purchaseId: '', // Will be set
          productId: item.productId,
          productName: item.productName,
          quantity: qty,
          costPrice: cost,
        ),
      );
    }

    final purchaseId = const Uuid().v4();
    final newPurchase = Purchase(
      id: purchaseId,
      supplierId: _selectedSupplier!.id,
      supplierName: _selectedSupplier!.name,
      purchaseDate: DateTime.now(),
      totalCost: totalCost,
      items:
          finalItems
              .map(
                (item) => PurchaseItem(
                  id: item.id,
                  purchaseId: purchaseId, // Assign the correct purchaseId
                  productId: item.productId,
                  productName: item.productName,
                  quantity: item.quantity,
                  costPrice: item.costPrice,
                ),
              )
              .toList(),
    );

    // Update product stock and cost price
    for (final item in newPurchase.items) {
      try {
        final product = productProvider.findById(item.productId);
        final updatedProduct = Product(
          id: product.id,
          name: product.name,
          description: product.description,
          price: product.price,
          costPrice:
              item.costPrice, // Also update cost price to latest purchase
          stock: product.stock + item.quantity, // Increase stock
          minStockLevel: product.minStockLevel,
          sku: product.sku,
          category: product.category,
          brand: product.brand,
          imageUrl: product.imageUrl,
          expirationDate: product.expirationDate,
        );
        await productProvider.updateProduct(updatedProduct);
      } catch (e) {
        debugPrint('Could not update stock for product ${item.productId}: $e');
      }
    }

    await purchaseProvider.addPurchase(newPurchase);

    if (!mounted) return;
    await showCharmingModal(
      context,
      title: 'Pembelian Berhasil',
      message: 'Data pembelian telah berhasil disimpan.',
    );

    navigator.pop();
  }

  @override
  void dispose() {
    _qtyControllers.forEach((_, controller) => controller.dispose());
    _costControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = Provider.of<SupplierProvider>(context).suppliers;
    final products = Provider.of<ProductProvider>(context).products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembelian Baru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _items.isEmpty ? null : _savePurchase,
            tooltip: 'Simpan Pembelian',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Supplier Selector
              Autocomplete<Supplier>(
                displayStringForOption: (Supplier option) => option.name,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<Supplier>.empty();
                  }
                  return suppliers.where((Supplier option) {
                    return option.name.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (Supplier selection) {
                  setState(() {
                    _selectedSupplier = selection;
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onSelected) {
                  if (_selectedSupplier != null && controller.text.isEmpty) {
                    controller.text = _selectedSupplier!.name;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Pilih Supplier',
                      border: const OutlineInputBorder(),
                      suffixIcon:
                          _selectedSupplier != null
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  controller.clear();
                                  setState(() {
                                    _selectedSupplier = null;
                                  });
                                },
                              )
                              : null,
                    ),
                    validator: (_) {
                      if (_selectedSupplier == null) {
                        return 'Supplier harus dipilih.';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Product Selector
              Autocomplete<Product>(
                displayStringForOption: (Product option) => option.name,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Product>.empty();
                  }
                  return products.where((Product option) {
                    return option.name.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (Product selection) {
                  _addProductToPurchase(selection);
                },
                fieldViewBuilder: (context, controller, focusNode, onSelected) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onFieldSubmitted: (_) {
                      // Clear the text field after selection
                      controller.clear();
                      onSelected();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Cari dan Tambah Produk',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  );
                },
              ),
              const Divider(height: 24),
              // Items List
              Expanded(
                child:
                    _items.isEmpty
                        ? const Center(
                          child: Text('Belum ada produk yang ditambahkan.'),
                        )
                        : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (ctx, index) {
                            final item = _items[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        controller: _qtyControllers[item.id],
                                        decoration: const InputDecoration(
                                          labelText: 'Qty',
                                        ),
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        validator:
                                            (v) =>
                                                (v == null ||
                                                        v.isEmpty ||
                                                        int.tryParse(v) ==
                                                            null ||
                                                        int.parse(v) <= 0)
                                                    ? '!'
                                                    : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 120,
                                      child: TextFormField(
                                        controller: _costControllers[item.id],
                                        decoration: const InputDecoration(
                                          labelText: 'Harga Beli',
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator:
                                            (v) =>
                                                (v == null ||
                                                        v.isEmpty ||
                                                        double.tryParse(v) ==
                                                            null ||
                                                        double.parse(v) < 0)
                                                    ? '!'
                                                    : null,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeItem(item.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/product_model.dart';
import 'package:pos_rp/providers/product_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProductFormDialog extends StatefulWidget {
  final Product? product;

  const ProductFormDialog({super.key, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;
  late double _price;
  late int _stock;
  late String _imageUrl; // Will store path or URL
  late String _sku;
  late String _category;
  late String _brand;
  late double _costPrice;
  late int _minStockLevel;
  DateTime? _expirationDate;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _name = widget.product!.name;
      _description = widget.product!.description;
      _price = widget.product!.price;
      _stock = widget.product!.stock;
      _imageUrl = widget.product!.imageUrl;
      _sku = widget.product!.sku;
      _category = widget.product!.category;
      _brand = widget.product!.brand;
      _costPrice = widget.product!.costPrice;
      _minStockLevel = widget.product!.minStockLevel;
      _expirationDate = widget.product!.expirationDate;
      if (!_imageUrl.startsWith('http')) {
        final file = File(_imageUrl);
        if (file.existsSync()) {
          _imageFile = file;
        }
      }
    } else {
      _name = '';
      _description = '';
      _price = 0.0;
      _stock = 0;
      _imageUrl = '';
      _sku = '';
      _category = '';
      _brand = '';
      _costPrice = 0.0;
      _minStockLevel = 0;
      _expirationDate = null;
    }
  }

  Future<void> _saveForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    _formKey.currentState!.save();

    // Hold the context sensitive references before the async gap.
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context);

    String finalImageUrl = _imageUrl;

    if (_imageFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(_imageFile!.path);
      final savedImage = await _imageFile!.copy('${appDir.path}/$fileName');
      finalImageUrl = savedImage.path;
    } else if (widget.product == null) {
      finalImageUrl =
          'https://via.placeholder.com/150/E0E0E0/000000?Text=No+Image';
    }

    Product? resultProduct;

    if (widget.product != null) {
      // Update existing product
      final updatedProduct = Product(
        id: widget.product!.id,
        name: _name,
        description: _description,
        price: _price,
        stock: _stock,
        imageUrl: finalImageUrl,
        sku: _sku,
        category: _category,
        brand: _brand,
        costPrice: _costPrice,
        minStockLevel: _minStockLevel,
        expirationDate: _expirationDate,
      );
      await productProvider.updateProduct(updatedProduct);
      resultProduct = updatedProduct;
    } else {
      // Add new product
      final newProduct = Product(
        id: const Uuid().v4(), // Generate a unique ID
        name: _name,
        description: _description,
        price: _price,
        stock: _stock,
        imageUrl: finalImageUrl,
        sku: _sku,
        category: _category,
        brand: _brand,
        costPrice: _costPrice,
        minStockLevel: _minStockLevel,
        expirationDate: _expirationDate,
      );
      await productProvider.addProduct(newProduct);
      resultProduct = newProduct;
    }

    navigator.pop(resultProduct);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
          child: Text(
            widget.product == null ? 'Add Product' : 'Edit Product',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
        Flexible(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: _buildImagePreview(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Please enter a name.' : null,
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _sku,
                    decoration: const InputDecoration(
                      labelText: 'SKU',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => _sku = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty
                                ? 'Please enter a description.'
                                : null,
                    onSaved: (value) => _description = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => _category = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _brand,
                    decoration: const InputDecoration(
                      labelText: 'Brand / Vendor',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => _brand = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _price.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty ||
                          double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Please enter a valid price.';
                      }
                      return null;
                    },
                    onSaved: (value) => _price = double.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _costPrice.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Cost Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty ||
                          double.tryParse(value) == null ||
                          double.parse(value) < 0) {
                        return 'Please enter a valid cost price.';
                      }
                      return null;
                    },
                    onSaved: (value) => _costPrice = double.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _stock.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty ||
                          int.tryParse(value) == null ||
                          int.parse(value) < 0) {
                        return 'Please enter a valid stock quantity.';
                      }
                      return null;
                    },
                    onSaved: (value) => _stock = int.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _minStockLevel.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Minimum Stock Level',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty ||
                          int.tryParse(value) == null ||
                          int.parse(value) < 0) {
                        return 'Please enter a valid minimum stock level.';
                      }
                      return null;
                    },
                    onSaved: (value) => _minStockLevel = int.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickExpirationDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Expiration Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            _expirationDate == null
                                ? 'Not set'
                                : DateFormat(
                                  'd MMM yyyy',
                                ).format(_expirationDate!),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _saveForm, child: const Text('Save')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (_imageUrl.startsWith('http')) {
      return Image.network(
        _imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder:
            (context, error, stackTrace) =>
                const Center(child: Icon(Icons.inventory_2)),
      );
    }
    return const Center(child: Icon(Icons.add_a_photo, color: Colors.grey));
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 600,
    );

    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _pickExpirationDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (pickedDate != null) {
      setState(() {
        _expirationDate = pickedDate;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Library'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () {
                    _pickImage(ImageSource.camera);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
    );
  }
}

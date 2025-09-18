import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/product_model.dart';
import 'package:pos_rp/providers/product_provider.dart';
import 'package:pos_rp/services/product_form_dialog.dart';
import 'package:pos_rp/widgets/sized_alert_dialog.dart';
import 'package:provider/provider.dart';

class ProductDetailDialog extends StatefulWidget {
  final Product product;
  final bool showAdminActions;

  const ProductDetailDialog({
    super.key,
    required this.product,
    this.showAdminActions = true,
  });

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  late Product product;

  @override
  void initState() {
    super.initState();
    product = widget.product;
  }

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final imageWidget = _buildProductImage(BoxFit.cover);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 16.0, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _showZoomableImage,
                  child: AspectRatio(aspectRatio: 3 / 4, child: imageWidget),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Selling Price:'),
                          Text(priceFormat.format(product.price)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cost Price:'),
                          Text(priceFormat.format(product.costPrice)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SKU:'),
                          Text(product.sku.isNotEmpty ? product.sku : '-'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Category:'),
                          Text(product.category),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Brand:'),
                          Text(product.brand.isNotEmpty ? product.brand : '-'),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Stock:'),
                          Text('${product.stock} units'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Min. Stock Level:'),
                          Text('${product.minStockLevel} units'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (product.expirationDate != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Expires On:'),
                            Text(
                              DateFormat(
                                'd MMM yyyy',
                              ).format(product.expirationDate!),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.showAdminActions)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  onPressed: () => Navigator.of(context).pop('delete'),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await showDialog<Product>(
                          context: context,
                          builder:
                              (ctx) => SizedAlertDialog(
                                child: ProductFormDialog(product: product),
                              ),
                        );

                        if (result != null && mounted) {
                          setState(() {
                            product = result;
                          });
                        }
                      },
                      child: const Text('Edit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProductImage(BoxFit fit) {
    if (product.imageUrl.startsWith('http')) {
      return Image.network(
        product.imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildImageError(),
      );
    } else {
      final file = File(product.imageUrl);
      if (file.existsSync()) {
        return Image.file(file, fit: fit);
      } else {
        return _buildImageError();
      }
    }
  }

  void _showZoomableImage() {
    // Don't show if there's no valid image
    if (product.imageUrl.isEmpty ||
        (!product.imageUrl.startsWith('http') &&
            !File(product.imageUrl).existsSync())) {
      return;
    }

    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(10),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: _buildProductImage(BoxFit.contain),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
      ),
    );
  }
}

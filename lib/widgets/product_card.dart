import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/product_model.dart';
import 'package:pos_rp/providers/cart_provider.dart';
import 'package:pos_rp/widgets/charming_modal.dart';
import 'package:pos_rp/widgets/product_detail_dialog.dart';
import 'package:pos_rp/widgets/sized_alert_dialog.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    final cartQuantity = cart.items[product.id]?.quantity ?? 0;
    final availableStock = product.stock - cartQuantity;
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder:
              (ctx) => SizedAlertDialog(
                child: ProductDetailDialog(
                  product: product,
                  showAdminActions: false,
                ),
              ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'product-image-${product.id}',
              child: Builder(
                builder: (context) {
                  final imageUrl = product.imageUrl;
                  if (imageUrl.startsWith('http')) {
                    return SizedBox.expand(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.inventory_2,
                                size: 50,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                      ),
                    );
                  }
                  final file = File(imageUrl);
                  if (file.existsSync()) {
                    return SizedBox.expand(
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.inventory_2,
                                size: 50,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                      ),
                    );
                  }
                  return SizedBox.expand(
                    child: Container(
                      color: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.inventory_2,
                        size: 50,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: theme.colorScheme.primary.withOpacity(0.95),
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 8.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(product.price),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Chip(
                label: Text(
                  'Stock: $availableStock',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor:
                    availableStock > 0
                        ? theme.colorScheme.primary.withOpacity(0.7)
                        : theme.colorScheme.error.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                visualDensity: VisualDensity.compact,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.hovered)) {
                      return Colors.black.withOpacity(0.5);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: MaterialStateProperty.resolveWith<Color?>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.hovered)) {
                      return Colors.white;
                    }
                    return theme.colorScheme.onPrimaryContainer;
                  }),
                  shape: MaterialStateProperty.all(const CircleBorder()),
                ),
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () async {
                  if (availableStock > 0) {
                    // Use listen:false inside a callback
                    Provider.of<CartProvider>(
                      context,
                      listen: false,
                    ).addItem(product.id, product.price, product.name);

                    showDialog(
                      context: context,
                      builder: (ctx) {
                        // This timer will automatically close the dialog after 1.5 seconds.
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          if (Navigator.of(ctx).canPop()) {
                            Navigator.of(ctx).pop();
                          }
                        });
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color:
                                      Colors.green, // Keeping green for success
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Added to Cart!',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${product.name} has been added to your cart.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text('Out of Stock'),
                            content: Text(
                              '${product.name} is currently out of stock.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

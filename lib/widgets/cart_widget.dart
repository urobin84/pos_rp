import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/customer_model.dart';
import 'package:pos_rp/providers/cart_provider.dart';
import 'package:pos_rp/providers/customer_provider.dart';
import 'package:pos_rp/widgets/payment_dialog.dart';
import 'package:provider/provider.dart';

class CartWidget extends StatelessWidget {
  const CartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    final customers = Provider.of<CustomerProvider>(context).customers;
    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text('Keranjang', style: Theme.of(context).textTheme.headlineSmall),
          const Divider(),
          _buildCustomerSelector(context, customers, cart),
          const Divider(),
          Expanded(
            // Use Expanded to fill available space
            child:
                cart.items.isEmpty
                    ? const Center(child: Text('Keranjang kosong'))
                    : ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (ctx, i) {
                        final productId = cart.items.keys.toList()[i];
                        final cartItem = cart.items.values.toList()[i];
                        return Dismissible(
                          key: ValueKey(cartItem.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            Provider.of<CartProvider>(
                              context,
                              listen: false,
                            ).removeItem(productId);
                          },
                          background: Container(
                            color: Theme.of(context).colorScheme.error,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 0,
                            ),
                            child: ListTile(
                              title: Text(cartItem.name),
                              subtitle: Text(
                                priceFormat.format(
                                  cartItem.price * cartItem.quantity,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      color: theme.colorScheme.error,
                                    ),
                                    onPressed:
                                        () => cart.removeSingleItem(productId),
                                  ),
                                  Text(
                                    '${cartItem.quantity}',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color: theme.colorScheme.primary,
                                    ),
                                    onPressed:
                                        () => cart.addItem(
                                          productId,
                                          cartItem.price,
                                          cartItem.name,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  priceFormat.format(cart.totalAmount),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  cart.totalAmount <= 0
                      ? null
                      : () {
                        showDialog(
                          context: context,
                          builder:
                              (ctx) =>
                                  PaymentDialog(totalAmount: cart.totalAmount),
                        );
                      },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Checkout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSelector(
    BuildContext context,
    List<Customer> customers,
    CartProvider cart,
  ) {
    return Autocomplete<Customer>(
      displayStringForOption:
          (Customer option) => '${option.name} - ${option.phone}',
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<Customer>.empty();
        }
        return customers.where((Customer option) {
          return option.phone.contains(textEditingValue.text) ||
              option.name.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
        });
      },
      onSelected: (Customer selection) {
        cart.selectCustomer(selection);
        FocusScope.of(context).unfocus(); // Hide keyboard
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // If a customer is already selected, show their name in the field.
        if (cart.selectedCustomer != null && fieldController.text.isEmpty) {
          fieldController.text =
              '${cart.selectedCustomer!.name} - ${cart.selectedCustomer!.phone}';
        }
        return TextFormField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            labelText: 'Cari Pelanggan (Nama/No. HP)',
            suffixIcon:
                cart.selectedCustomer != null
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        fieldController.clear();
                        cart.clearCustomer();
                      },
                    )
                    : null,
          ),
        );
      },
    );
  }
}

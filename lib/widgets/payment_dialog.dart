import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pos_rp/models/product_model.dart';
import 'package:pos_rp/models/transaction_model.dart';
import 'package:pos_rp/models/transaction_item_model.dart';
import 'package:pos_rp/providers/cart_provider.dart';
import 'package:pos_rp/providers/product_provider.dart';
import 'package:pos_rp/providers/transaction_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:pos_rp/widgets/currency_input_formatter.dart';
import 'package:pos_rp/widgets/receipt_view_dialog.dart';

enum PaymentMethod { cash, transfer }

class PaymentDialog extends StatefulWidget {
  final double totalAmount;

  const PaymentDialog({super.key, required this.totalAmount});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _cashController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _additionalCostsController = TextEditingController(text: '0');
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _change = 0.0;
  double _cashGiven = 0.0;
  double _discount = 0.0;
  double _additionalCosts = 0.0;
  late double _finalTotalAmount;

  @override
  void initState() {
    super.initState();
    _finalTotalAmount = widget.totalAmount;
    _cashController.addListener(_calculateChange);
    _discountController.addListener(_recalculateTotals);
    _additionalCostsController.addListener(_recalculateTotals);
  }

  @override
  void dispose() {
    _cashController.removeListener(_calculateChange);
    _cashController.dispose();
    _discountController.removeListener(_recalculateTotals);
    _discountController.dispose();
    _audioPlayer.dispose();
    _additionalCostsController.removeListener(_recalculateTotals);
    _additionalCostsController.dispose();
    super.dispose();
  }

  void _recalculateTotals() {
    setState(() {
      final cleanDiscount = _discountController.text.replaceAll('.', '');
      final cleanCosts = _additionalCostsController.text.replaceAll('.', '');

      _discount = double.tryParse(cleanDiscount) ?? 0.0;
      _additionalCosts = double.tryParse(cleanCosts) ?? 0.0;
      _finalTotalAmount = widget.totalAmount - _discount + _additionalCosts;
      // Ensure final amount is not negative
      if (_finalTotalAmount < 0) {
        _finalTotalAmount = 0;
      }
      _calculateChange(); // Recalculate change as well
    });
  }

  void _calculateChange() {
    setState(() {
      final cleanCash = _cashController.text.replaceAll('.', '');
      _cashGiven = double.tryParse(cleanCash) ?? 0.0;
      if (_cashGiven >= _finalTotalAmount) {
        _change = _cashGiven - _finalTotalAmount;
      } else {
        _change = 0.0;
      }
    });
  }

  Future<void> _confirmPayment() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final BuildContext buildContext =
        context; // Capture context before async gap
    final navigator = Navigator.of(context);

    String successMessage = 'Checkout berhasil!';
    if (_selectedMethod == PaymentMethod.cash) {
      final priceFormat = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      successMessage += ' Kembalian: ${priceFormat.format(_change)}';
    }

    final transactionId = const Uuid().v4();
    final newTransaction = Transaction(
      id: transactionId,
      items:
          cart.items.entries.map((entry) {
            final productId = entry.key;
            final cartItem = entry.value;
            // Find the product to get its cost price
            final product = productProvider.findById(productId);
            return TransactionItem(
              id: const Uuid().v4(),
              transactionId: transactionId,
              productId: productId,
              productName: cartItem.name,
              quantity: cartItem.quantity,
              price: cartItem.price,
              costPrice: product.costPrice, // Snapshot the cost price
            );
          }).toList(),
      paymentMethod: _selectedMethod.name,
      customerName: cart.selectedCustomer?.name ?? 'Walk-in Customer',
      createdAt: DateTime.now(),
      subtotal: cart.totalAmount,
      discount: _discount,
      additionalCosts: _additionalCosts,
      totalAmount: _finalTotalAmount,
    );

    await transactionProvider.addTransaction(newTransaction);

    // Correct the stock for each product sold
    for (final item in newTransaction.items) {
      try {
        final product = productProvider.findById(item.productId);
        final updatedProduct = Product(
          id: product.id,
          name: product.name,
          description: product.description,
          price: product.price,
          costPrice: product.costPrice,
          stock: product.stock - item.quantity, // Decrease stock
          minStockLevel: product.minStockLevel,
          sku: product.sku,
          category: product.category,
          brand: product.brand,
          imageUrl: product.imageUrl,
          expirationDate: product.expirationDate,
        );
        await productProvider.updateProduct(updatedProduct);
      } catch (e) {
        // Handle case where product might not be found, though it should exist.
        debugPrint('Could not update stock for product ${item.productId}: $e');
      }
    }

    // Play success sound without waiting for it to complete
    _audioPlayer.play(
      AssetSource('sounds/success.mp3'),
      mode: PlayerMode.lowLatency,
    );

    // Pop the payment dialog
    navigator.pop();
    // Pop the cart bottom sheet if it's open
    if (navigator.canPop()) {
      navigator.pop();
    }

    cart.clear();
    await showDialog(
      context: buildContext,
      barrierDismissible: false, // User must explicitly close it
      builder: (ctx) => ReceiptViewDialog(transaction: newTransaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final bool canConfirmCash =
        _selectedMethod == PaymentMethod.cash &&
        _cashGiven >= _finalTotalAmount;
    final bool canConfirmTransfer = _selectedMethod == PaymentMethod.transfer;

    return AlertDialog(
      title: const Text('Pilih Metode Pembayaran'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subtotal: ${priceFormat.format(widget.totalAmount)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Diskon',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _additionalCostsController,
              decoration: const InputDecoration(
                labelText: 'Biaya Tambahan (Pajak, dll)',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
            ),
            const Divider(height: 24),
            Text(
              'Total Tagihan: ${priceFormat.format(_finalTotalAmount)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SegmentedButton<PaymentMethod>(
              segments: <ButtonSegment<PaymentMethod>>[
                ButtonSegment<PaymentMethod>(
                  value: PaymentMethod.cash,
                  label: const Text('Tunai'),
                  icon: Icon(Icons.money, color: theme.colorScheme.primary),
                ),
                ButtonSegment<PaymentMethod>(
                  value: PaymentMethod.transfer,
                  label: const Text('Transfer'),
                  icon: Icon(
                    Icons.credit_card,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              selected: {_selectedMethod},
              onSelectionChanged: (Set<PaymentMethod> newSelection) {
                setState(() => _selectedMethod = newSelection.first);
              },
            ),
            const SizedBox(height: 20),
            if (_selectedMethod == PaymentMethod.cash)
              _buildCashPaymentUI(priceFormat)
            else
              _buildTransferPaymentUI(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed:
              (canConfirmCash || canConfirmTransfer) ? _confirmPayment : null,
          child: const Text('Konfirmasi Pembayaran'),
        ),
      ],
    );
  }

  Widget _buildCashPaymentUI(NumberFormat priceFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _cashController,
          decoration: const InputDecoration(
            labelText: 'Uang Tunai Diberikan',
            prefixText: 'Rp ',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          autofocus: true,
        ),
        const SizedBox(height: 16),
        Text(
          'Kembalian: ${priceFormat.format(_change)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTransferPaymentUI() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Silakan transfer ke rekening berikut:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('Bank ABC: 1234-5678-9012'),
        Text('a/n POS RP'),
      ],
    );
  }
}

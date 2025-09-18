import 'package:pos_rp/models/transaction_item_model.dart';

class Transaction {
  final String id;
  final String customerName;
  final String paymentMethod;
  final DateTime createdAt;
  final List<TransactionItem> items;

  // New Fields
  final String status; // e.g., 'Completed', 'Canceled', 'Refunded'
  final String cashierName;
  final double subtotal; // Total before discount and costs
  final double discount;
  final double additionalCosts;
  final double
  totalAmount; // Final amount: subtotal - discount + additionalCosts

  Transaction({
    required this.id,
    required this.customerName,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
    this.status = 'Completed',
    this.cashierName = 'Admin',
    required this.subtotal,
    this.discount = 0.0,
    this.additionalCosts = 0.0,
    required this.totalAmount,
  });

  // Helper to convert for DB insertion (omitting items list)
  Map<String, dynamic> toMapForDb() {
    return {
      'id': id,
      'customerName': customerName,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'cashierName': cashierName,
      'subtotal': subtotal,
      'discount': discount,
      'additionalCosts': additionalCosts,
      'totalAmount': totalAmount,
    };
  }

  static Transaction fromMap(
    Map<String, dynamic> transactionMap,
    List<TransactionItem> items,
  ) {
    return Transaction(
      id: transactionMap['id'],
      customerName: transactionMap['customerName'],
      paymentMethod: transactionMap['paymentMethod'],
      createdAt: DateTime.parse(transactionMap['createdAt']),
      items: items,
      status: transactionMap['status'] ?? 'Completed',
      cashierName: transactionMap['cashierName'] ?? 'N/A',
      subtotal: transactionMap['subtotal'] ?? 0.0,
      discount: transactionMap['discount'] ?? 0.0,
      additionalCosts: transactionMap['additionalCosts'] ?? 0.0,
      totalAmount: transactionMap['totalAmount'],
    );
  }
}

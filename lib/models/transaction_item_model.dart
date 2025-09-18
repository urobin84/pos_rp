class TransactionItem {
  final String id;
  final String transactionId;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double costPrice; // New field

  TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.costPrice, // New field
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'costPrice': costPrice, // New field
    };
  }

  static TransactionItem fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      transactionId: map['transactionId'],
      productId: map['productId'],
      productName: map['productName'],
      quantity: map['quantity'],
      price: map['price'],
      costPrice: map['costPrice'] ?? 0.0, // New field with fallback
    );
  }
}

class PurchaseItem {
  final String id;
  final String purchaseId;
  final String productId;
  final String productName;
  final int quantity;
  final double costPrice; // The cost at the time of purchase

  PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.costPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchaseId': purchaseId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'costPrice': costPrice,
    };
  }

  static PurchaseItem fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'],
      purchaseId: map['purchaseId'],
      productId: map['productId'],
      productName: map['productName'],
      quantity: map['quantity'],
      costPrice: map['costPrice'],
    );
  }
}

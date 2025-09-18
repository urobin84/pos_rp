import 'package:pos_rp/models/purchase_item_model.dart';

class Purchase {
  final String id;
  final String supplierId;
  final String supplierName;
  final DateTime purchaseDate;
  final double totalCost;
  final List<PurchaseItem> items;

  Purchase({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.purchaseDate,
    required this.totalCost,
    required this.items,
  });

  Map<String, dynamic> toMapForDb() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'purchaseDate': purchaseDate.toIso8601String(),
      'totalCost': totalCost,
    };
  }

  static Purchase fromMap(
    Map<String, dynamic> purchaseMap,
    List<PurchaseItem> items,
  ) {
    return Purchase(
      id: purchaseMap['id'],
      supplierId: purchaseMap['supplierId'],
      supplierName: purchaseMap['supplierName'],
      purchaseDate: DateTime.parse(purchaseMap['purchaseDate']),
      totalCost: purchaseMap['totalCost'],
      items: items,
    );
  }
}

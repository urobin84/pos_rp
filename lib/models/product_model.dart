// A model class for a product.
class Product {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price; // Selling Price
  int stock;
  final String sku;
  final String category;
  final String brand;
  final double costPrice;
  final int minStockLevel;
  final DateTime? expirationDate;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.stock = 0,
    this.sku = '',
    this.category = 'Uncategorized',
    this.brand = '',
    this.costPrice = 0.0,
    this.minStockLevel = 0,
    this.expirationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'stock': stock,
      'sku': sku,
      'category': category,
      'brand': brand,
      'costPrice': costPrice,
      'minStockLevel': minStockLevel,
      'expirationDate': expirationDate?.toIso8601String(),
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      imageUrl: map['imageUrl'] as String,
      price: map['price'] as double,
      stock: map['stock'] as int,
      sku: map['sku'] ?? '',
      category: map['category'] ?? 'Uncategorized',
      brand: map['brand'] ?? '',
      costPrice: map['costPrice'] ?? 0.0,
      minStockLevel: map['minStockLevel'] ?? 0,
      expirationDate:
          map['expirationDate'] != null
              ? DateTime.parse(map['expirationDate'])
              : null,
    );
  }
}

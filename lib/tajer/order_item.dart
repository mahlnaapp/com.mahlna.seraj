class OrderItems {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String image;
  final String storeId;
  final String storeName;

  OrderItems({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    required this.storeId,
    required this.storeName,
  });

  factory OrderItems.fromMap(Map<String, dynamic> map) {
    return OrderItems(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 1,
      image: map['image'] ?? '',
      storeId: map['storeId'] ?? '',
      storeName: map['storeName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
      'storeId': storeId,
      'storeName': storeName,
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String image;
  final String storeId;
  final String storeName;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    required this.storeId,
    required this.storeName,
  });

  @override
  String toString() {
    return 'OrderItem{product: $name, qty: $quantity, price: $price, store: $storeName}';
  }
}

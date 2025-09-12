// أضف هذا الكود في ملف models.dart
class DeliveryOrder {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final double totalAmount;
  final DateTime orderDate;
  String status;
  List<OrderItem> items = [];
  String? deliveryAgentName;

  DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    this.deliveryAgentName,
  });
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String storeId;
  final String storeName;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.storeId,
    required this.storeName,
  });
}

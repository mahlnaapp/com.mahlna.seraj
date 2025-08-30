import 'package:appfotajer/order_item_model.dart';

class Order {
  final String id;
  final String userId;
  final String customerName; // أضف هذا الحقل
  final DateTime orderDate;
  final double totalAmount;
  final String status;
  final String deliveryAddress;
  final String phone;
  final List<OrderItem> items;
  final bool isMultiStore;
  final String? storeName;
  final String? storeId;

  Order({
    required this.id,
    required this.userId,
    required this.customerName, // أضف هنا
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.phone,
    required this.items,
    required this.isMultiStore,
    this.storeName,
    this.storeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'customerName': customerName, // أضف هنا
      'orderDate': orderDate.toIso8601String(),
      'totalAmount': totalAmount,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'phone': phone,
      'isMultiStore': isMultiStore,
      'storeName': storeName,
      'storeId': storeId,
    };
  }
}

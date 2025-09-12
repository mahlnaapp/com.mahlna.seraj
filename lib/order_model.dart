import 'package:appfotajer/order_item_model.dart';

class Order {
  final String id;
  final String userId;
  final String customerName;
  final DateTime orderDate;
  final double totalAmount;
  final String status;
  final String deliveryAddress;
  final String phone;
  final List<OrderItem> items;
  final bool isMultiStore;
  final String? storeName;
  final String? storeId;
  final String? zoneId; // 🔹 تم إضافة حقل zoneId هنا

  Order({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.phone,
    required this.items,
    required this.isMultiStore,
    this.storeName,
    this.storeId,
    this.zoneId, // 🔹 تم إضافة zoneId إلى المُنشئ (Constructor)
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'customerName': customerName,
      'orderDate': orderDate.toIso8601String(),
      'totalAmount': totalAmount,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'phone': phone,
      'isMultiStore': isMultiStore,
      'storeName': storeName,
      'storeId': storeId,
      'zoneId': zoneId, // 🔹 تم إضافة zoneId إلى خريطة البيانات (Map)
    };
  }
}

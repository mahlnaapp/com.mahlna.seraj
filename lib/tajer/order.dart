import 'order_item.dart';

class Order {
  final String id;
  final String userId;
  final String customerName;
  final DateTime orderDate;
  double totalAmount;
  final String status;
  final String deliveryAddress;
  final String phone;
  List<OrderItems> items;
  final bool isMultiStore;
  final String? storeName;
  final String? storeId;

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
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['\$id'] ?? '',
      userId: map['userId'] ?? '',
      customerName: map['customerName'] ?? '',
      orderDate: DateTime.parse(map['orderDate']),
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      status: map['status'] ?? '',
      deliveryAddress: map['deliveryAddress'] ?? '',
      phone: map['phone'] ?? '',
      items: [],
      isMultiStore: map['isMultiStore'] ?? false,
      storeName: map['storeName'],
      storeId: map['storeId'],
    );
  }

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
    };
  }
}

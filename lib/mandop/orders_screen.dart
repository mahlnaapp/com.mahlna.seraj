// أضف هذا الكود في ملف screens/orders_screen.dart
import 'package:flutter/material.dart';
import '../mandop/models.dart';
import '../mandop/order_card.dart';

class OrdersScreen extends StatelessWidget {
  final List<DeliveryOrder> orders;
  final String status;
  final String zoneId;

  const OrdersScreen({
    super.key,
    required this.orders,
    required this.status,
    required this.zoneId,
  });

  @override
  Widget build(BuildContext context) {
    return orders.isEmpty
        ? Center(child: Text('لا توجد طلبات $status'))
        : ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(order: order, status: status, zoneId: zoneId);
            },
          );
  }
}

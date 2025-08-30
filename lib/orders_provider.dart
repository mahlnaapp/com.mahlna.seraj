import 'package:flutter/material.dart';
import 'order_model.dart';

class OrdersProvider with ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders.reversed.toList());

  void addOrder(Order order) {
    _orders.add(order);
    notifyListeners();
  }

  List<Order> getOrdersForStore(String storeId) {
    return _orders.where((order) {
      return order.items.any((item) => item.storeId == storeId);
    }).toList();
  }
}

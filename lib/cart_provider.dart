import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  // 🔹 إضافة متغير لحفظ معرف القاطع/المنطقة
  String? _selectedZoneId;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  String get formattedTotalPrice =>
      NumberFormat.currency(symbol: 'د.ع', decimalDigits: 0).format(totalPrice);

  List<String> get uniqueStoreIds {
    return _items.map((item) => item.storeId).toSet().toList();
  }

  List<CartItem> getItemsByStore(String storeId) {
    return _items.where((item) => item.storeId == storeId).toList();
  }

  double getSubtotalByStore(String storeId) {
    return _items
        .where((item) => item.storeId == storeId)
        .fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  // 🔹 دالة جديدة للوصول إلى المتغير
  String? get selectedZoneId => _selectedZoneId;

  // 🔹 دالة جديدة لتحديث معرف القاطع/المنطقة
  void updateZoneId(String? zoneId) {
    _selectedZoneId = zoneId;
    notifyListeners();
  }

  void addItemWithNotification(
    BuildContext context, {
    required String productId,
    required String name,
    required double price,
    required String image,
    required String storeId,
    required String storeName,
  }) {
    final existingIndex = _items.indexWhere(
      (item) => item.productId == productId && item.storeId == storeId,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(
        CartItem(
          id: DateTime.now().toString(),
          productId: productId,
          name: name,
          price: price,
          image: image,
          storeId: storeId,
          storeName: storeName,
        ),
      );
    }

    _showSuccessNotification(context, name);
    notifyListeners();
  }

  void addItem(
    String productId,
    String name,
    double price,
    String image,
    String storeId,
    String storeName,
  ) {
    final existingIndex = _items.indexWhere(
      (item) => item.productId == productId && item.storeId == storeId,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(
        CartItem(
          id: DateTime.now().toString(),
          productId: productId,
          name: name,
          price: price,
          image: image,
          storeId: storeId,
          storeName: storeName,
        ),
      );
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      _items[index].quantity = newQuantity;
      notifyListeners();
    }
  }

  void _showSuccessNotification(BuildContext context, String productName) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة $productName إلى السلة'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void removeAllItems() {
    _items.clear();
    notifyListeners();
  }
}

class CartItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final String image;
  final String storeId;
  final String storeName;
  int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.storeId,
    required this.storeName,
    this.quantity = 1,
  });
}

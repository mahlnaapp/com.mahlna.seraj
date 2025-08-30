import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'order_model.dart';
import 'order_item_model.dart';

class OrderService {
  final Databases _databases;
  static const String _databaseId = 'mahllnadb';
  static const String _ordersCollection = 'Orders';
  static const String _orderItemsCollection = 'OrderItems';

  OrderService(this._databases);

  Future<void> createOrder(Order order) async {
    try {
      final orderDoc = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _ordersCollection,
        documentId: ID.unique(),
        data: order.toMap(),
      );

      for (final item in order.items) {
        await _databases.createDocument(
          databaseId: _databaseId,
          collectionId: _orderItemsCollection,
          documentId: ID.unique(),
          data: {
            'orderId': orderDoc.$id,
            'productId': item.productId,
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'image': item.image,
            'storeId': item.storeId,
            'storeName': item.storeName,
            'status': 'pending',
          },
        );
      }
    } catch (e) {
      debugPrint('Error creating order: $e');
      throw Exception('Failed to create order');
    }
  }

  Future<List<OrderItem>> getOrderItemsForStore(String storeId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _orderItemsCollection,
        queries: [Query.equal('storeId', storeId)],
      );

      return response.documents.map((doc) {
        return OrderItem(
          productId: doc.data['productId'],
          name: doc.data['name'],
          price: doc.data['price'].toDouble(),
          quantity: doc.data['quantity'].toInt(),
          image: doc.data['image'],
          storeId: doc.data['storeId'],
          storeName: doc.data['storeName'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching order items: $e');
      throw Exception('Failed to load order items');
    }
  }
}

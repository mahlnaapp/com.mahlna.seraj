import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:intl/intl.dart';

import '../tajer/store.dart';
import '../tajer/product.dart';
import '../tajer/product_category.dart';
import '../tajer/order.dart';
import '../tajer/order_item.dart';

class MerchantProvider with ChangeNotifier {
  final Databases _databases;
  final Storage _storage;
  final String _storeId;

  bool _isLoading = true;
  Store? _store;
  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  List<Order> _orders = [];

  MerchantProvider(this._databases, this._storage, this._storeId) {
    _init();
  }

  bool get isLoading => _isLoading;
  Store? get store => _store;
  List<Product> get products => _products;
  List<Order> get orders => _orders;
  List<ProductCategory> get categories => _categories;

  // أضفت هذه الخصائص العامة للوصول من خارج هذا الملف
  Databases get databases => _databases;
  Storage get storage => _storage;

  Future<void> _init() async {
    await _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch store data
      final storeDoc = await _databases.getDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Stores',
        documentId: _storeId,
      );
      _store = Store.fromMap(storeDoc.data);

      // Fetch products data
      final productsRes = await _databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'Products',
        queries: [Query.equal('storeId', _storeId), Query.limit(1000)],
      );
      _products = productsRes.documents
          .map((doc) => Product.fromMap(doc.data))
          .toList();

      // Fetch categories data
      final categoriesRes = await _databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'ProductCategories',
        queries: [
          Query.equal('storeId', _storeId),
          Query.orderAsc('order'),
          Query.limit(1000),
        ],
      );
      _categories = categoriesRes.documents
          .map((doc) => ProductCategory.fromMap(doc.data))
          .toList();

      // Fetch all order items for this store first
      final orderItemsRes = await _databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'OrderItems',
        queries: [Query.equal('storeId', _storeId), Query.limit(1000)],
      );

      // Extract unique orderIds
      final orderIds = orderItemsRes.documents
          .map((doc) => doc.data['orderId'] as String)
          .toSet()
          .toList();

      // Fetch order details in a batch
      final ordersRes = await _databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'Orders',
        queries: [
          Query.equal('\$id', orderIds),
          Query.orderDesc('\$createdAt'),
          Query.limit(100000),
        ],
      );

      _orders.clear();
      for (final orderDoc in ordersRes.documents) {
        final order = Order.fromMap(orderDoc.data);
        final itemsForThisStore = orderItemsRes.documents
            .where((item) => item.data['orderId'] == order.id)
            .map((doc) => OrderItems.fromMap(doc.data))
            .toList();
        order.items = itemsForThisStore;
        order.totalAmount = itemsForThisStore.fold(
          0,
          (sum, item) => sum + (item.price * item.quantity),
        );
        _orders.add(order);
      }

      _orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading store data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await _loadStoreData();
  }

  Future<void> updateStoreStatus(bool isOpen) async {
    try {
      await _databases.updateDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Stores',
        documentId: _storeId,
        data: {'isOpen': isOpen},
      );
      _store!.isOpen = isOpen;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating store status: $e');
      rethrow;
    }
  }

  Future<void> updateStoreDetails({
    required String name,
    required String category,
    required double latitude,
    required double longitude,
    required String image,
    String? address,
    String? phone,
  }) async {
    try {
      await _databases.updateDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Stores',
        documentId: _storeId,
        data: {
          'name': name,
          'category': category,
          'latitude': latitude,
          'longitude': longitude,
          'image': image,
        },
      );
      _store = _store!.copyWith(
        name: name,
        category: category,
        latitude: latitude,
        longitude: longitude,
        image: image,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating store details: $e');
      rethrow;
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      final newProduct = product.copyWith(storeId: _storeId);
      final res = await _databases.createDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Products',
        documentId: ID.unique(),
        data: newProduct.toMap(),
      );
      _products.add(Product.fromMap(res.data));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _databases.updateDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Products',
        documentId: product.id,
        data: product.toMap(),
      );
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> addCategory(String name) async {
    try {
      final newCategory = ProductCategory(
        id: ID.unique(),
        name: name,
        storeId: _storeId,
        order: _categories.length,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final res = await _databases.createDocument(
        databaseId: 'mahllnadb',
        collectionId: 'ProductCategories',
        documentId: newCategory.id,
        data: newCategory.toMap(),
      );

      _categories.add(ProductCategory.fromMap(res.data));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {}

  Future<void> logout() async {}
}

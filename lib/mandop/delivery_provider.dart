// ملف delivery_provider.dart
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'app_constants.dart';
import 'models.dart';
import 'notifications_service.dart';

class DeliveryProvider with ChangeNotifier {
  final Databases _databases;
  final Client _client;
  late final Realtime _realtime;
  RealtimeSubscription? _subscription;
  String? _currentAgentId;
  String? _currentAgentName;
  String? _currentAgentZoneName;
  double _totalEarnings = 0.0;
  double _appDues = 0.0;
  bool _loginAllowed = true;

  List<DeliveryOrder> _readyOrders = [];
  List<DeliveryOrder> _inProgressOrders = [];
  List<DeliveryOrder> _completedOrders = [];
  bool _isLoading = false;
  final Map<String, String> _storeImages = {};
  final Map<String, String> _productImages = {};

  DeliveryProvider(this._databases, this._client) {
    _realtime = Realtime(_client);
  }

  // ===================== دالة جديدة لتعيين المندوب الحالي بالكامل =====================
  void setCurrentAgent({
    required String agentId,
    String? agentName,
    String? agentZoneName,
  }) {
    _currentAgentId = agentId;
    if (agentName != null) _currentAgentName = agentName;
    if (agentZoneName != null) _currentAgentZoneName = agentZoneName;
    notifyListeners();
  }

  void setCurrentAgentId(String agentId) {
    _currentAgentId = agentId;
  }

  String? get currentAgentId => _currentAgentId;
  String? get currentAgentName => _currentAgentName;
  String? get currentAgentZoneName => _currentAgentZoneName;
  double get totalEarnings => _totalEarnings;
  double get appDues => _appDues;
  bool get loginAllowed => _loginAllowed;

  List<DeliveryOrder> get readyOrders => _readyOrders;
  List<DeliveryOrder> get inProgressOrders => _inProgressOrders;
  List<DeliveryOrder> get completedOrders => _completedOrders;
  bool get isLoading => _isLoading;

  String getStoreImage(String storeId) => _storeImages[storeId] ?? '';
  String getProductImage(String productId) => _productImages[productId] ?? '';

  Future<void> loadAllOrders({required String zoneId}) async {
    if (_currentAgentId == null) return;
    try {
      _isLoading = true;
      notifyListeners();

      final readyResponse = await _databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.ordersCollectionId,
        queries: [
          Query.equal('zoneId', zoneId),
          Query.equal('status', 'جاهزة للتوصيل'),
          Query.isNull('deliveryAgentId'),
        ],
      );

      final inProgressResponse = await _databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.ordersCollectionId,
        queries: [
          Query.equal('zoneId', zoneId),
          Query.equal('status', 'قيد التوصيل'),
          Query.equal('deliveryAgentId', _currentAgentId),
        ],
      );

      final completedResponse = await _databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.ordersCollectionId,
        queries: [
          Query.equal('zoneId', zoneId),
          Query.equal('status', 'تم التسليم'),
          Query.equal('deliveryAgentId', _currentAgentId),
        ],
      );

      _readyOrders = [];
      _inProgressOrders = [];
      _completedOrders = [];
      _storeImages.clear();
      _productImages.clear();

      await _processDocuments(readyResponse.documents, _readyOrders);
      await _processDocuments(inProgressResponse.documents, _inProgressOrders);
      await _processDocuments(completedResponse.documents, _completedOrders);

      _readyOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      _inProgressOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      _completedOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAgentDashboardData(String agentId) async {
    try {
      final agentDoc = await _databases.getDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.agentsCollectionId,
        documentId: agentId,
      );

      _currentAgentName = agentDoc.data['agentName'];
      _currentAgentZoneName = agentDoc.data['zoneId'];
      _appDues = (agentDoc.data['appDues'] as num?)?.toDouble() ?? 0.0;
      _totalEarnings =
          (agentDoc.data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
      _loginAllowed = (agentDoc.data['loginAllowed'] as bool?) ?? true;

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching agent dashboard data: $e");
    }
  }

  Future<void> _updateAgentDues(String agentId, double totalAmount) async {
    try {
      final agentDoc = await _databases.getDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.agentsCollectionId,
        documentId: agentId,
      );

      final currentDues = (agentDoc.data['appDues'] as num).toDouble();
      final currentEarnings = (agentDoc.data['totalEarnings'] as num)
          .toDouble();

      final deliveryFee = _calculateDeliveryFee(totalAmount);
      final newAppDues = currentDues + (deliveryFee * 0.20);
      final newTotalEarnings = currentEarnings + (deliveryFee * 0.80);

      await _databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.agentsCollectionId,
        documentId: agentId,
        data: {'appDues': newAppDues, 'totalEarnings': newTotalEarnings},
      );
    } catch (e) {
      debugPrint("Error updating app dues: $e");
    }
  }

  Future<bool> checkAndSetLoginAllowed() async {
    if (_appDues >= 5250) {
      await _databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.agentsCollectionId,
        documentId: _currentAgentId!,
        data: {'loginAllowed': false},
      );
      _loginAllowed = false;
      return true;
    }
    return false;
  }

  double _calculateDeliveryFee(double total) {
    if (total <= 2500) {
      return 250;
    } else if (total <= 10000) {
      return 500;
    } else if (total < 20000) {
      return 1000;
    } else {
      return ((total ~/ 10000) * 1000).toDouble();
    }
  }

  Future<void> _processDocuments(
    List<models.Document> documents,
    List<DeliveryOrder> list,
  ) async {
    for (var doc in documents) {
      String? deliveryAgentName;
      if (doc.data['status'] == 'تم التسليم' &&
          doc.data['deliveryAgentId'] != null) {
        try {
          final agentDoc = await _databases.getDocument(
            databaseId: AppConstants.databaseId,
            collectionId: AppConstants.agentsCollectionId,
            documentId: doc.data['deliveryAgentId'],
          );
          deliveryAgentName = agentDoc.data['agentName'];
        } catch (e) {
          debugPrint('Error fetching agent name: $e');
        }
      }

      final order = DeliveryOrder(
        id: doc.$id,
        customerName: doc.data['customerName'] ?? 'N/A',
        phone: doc.data['phone'] ?? 'N/A',
        address: doc.data['deliveryAddress'] ?? 'N/A',
        totalAmount: (doc.data['totalAmount'] as num).toDouble(),
        orderDate: DateTime.parse(doc.data['orderDate']),
        status: doc.data['status'] ?? 'N/A',
        deliveryAgentName: deliveryAgentName,
      );

      final itemsResponse = await _databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.orderItemsCollectionId,
        queries: [Query.equal('orderId', order.id)],
      );

      order.items = await Future.wait(
        itemsResponse.documents.map((itemDoc) async {
          if (!_productImages.containsKey(itemDoc.data['productId'])) {
            try {
              final product = await _databases.getDocument(
                databaseId: AppConstants.databaseId,
                collectionId: AppConstants.productsCollectionId,
                documentId: itemDoc.data['productId'],
              );
              _productImages[itemDoc.data['productId']] =
                  product.data['image'] ?? '';
            } catch (e) {
              _productImages[itemDoc.data['productId']] = '';
            }
          }
          if (!_storeImages.containsKey(itemDoc.data['storeId'])) {
            try {
              final store = await _databases.getDocument(
                databaseId: AppConstants.databaseId,
                collectionId: AppConstants.storesCollectionId,
                documentId: itemDoc.data['storeId'],
              );
              _storeImages[itemDoc.data['storeId']] = store.data['image'] ?? '';
            } catch (e) {
              _storeImages[itemDoc.data['storeId']] = '';
            }
          }
          return OrderItem(
            productId: itemDoc.data['productId'],
            productName: itemDoc.data['name'],
            quantity: itemDoc.data['quantity'],
            price: (itemDoc.data['price'] as num).toDouble(),
            storeId: itemDoc.data['storeId'],
            storeName: itemDoc.data['storeName'],
          );
        }),
      );
      list.add(order);
    }
  }

  void startRealtimeListener({required String zoneId}) {
    _subscription?.close();

    _subscription = _realtime.subscribe([
      'databases.${AppConstants.databaseId}.collections.${AppConstants.ordersCollectionId}.documents',
    ]);

    _subscription?.stream.listen((response) {
      if (response.events.contains(
        'databases.*.collections.*.documents.*.create',
      )) {
        final newOrderZoneId = response.payload['zoneId'];
        if (newOrderZoneId == zoneId) {
          showNewOrderNotification();
          loadAllOrders(zoneId: zoneId);
        }
      }
      if (response.events.contains(
        'databases.*.collections.*.documents.*.update',
      )) {
        final updatedOrder = response.payload;
        final updatedAgentId = updatedOrder['deliveryAgentId'];
        if (updatedAgentId == _currentAgentId || updatedAgentId == null) {
          loadAllOrders(zoneId: zoneId);
        }
      }
    });
  }

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    required String zoneId,
  }) async {
    try {
      final dataToUpdate = {'status': newStatus};

      if (newStatus == 'قيد التوصيل' && _currentAgentId != null) {
        dataToUpdate['deliveryAgentId'] = _currentAgentId!;
      } else if (newStatus == 'تم التسليم' && _currentAgentId != null) {
        dataToUpdate['deliveryAgentId'] = _currentAgentId!;
        final orderDoc = await _databases.getDocument(
          databaseId: AppConstants.databaseId,
          collectionId: AppConstants.ordersCollectionId,
          documentId: orderId,
        );
        final totalAmount = (orderDoc.data['totalAmount'] as num).toDouble();
        await _updateAgentDues(_currentAgentId!, totalAmount);
        await _incrementCompletedOrdersCount(_currentAgentId!);

        await checkAndSetLoginAllowed();
      }

      await _databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.ordersCollectionId,
        documentId: orderId,
        data: dataToUpdate,
      );

      await loadAllOrders(zoneId: zoneId);
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  Future<void> _incrementCompletedOrdersCount(String agentId) async {
    try {
      final agentDoc = await _databases.getDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.agentsCollectionId,
        documentId: agentId,
      );

      final currentCount = (agentDoc.data['completedOrdersCount'] as num)
          .toInt();
      final newCount = currentCount + 1;

      await _databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.agentsCollectionId,
        documentId: agentId,
        data: {'completedOrdersCount': newCount},
      );
    } catch (e) {
      debugPrint('Error incrementing completed orders count: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}

// File: store_service.dart

import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'store_model.dart';

class StoreService {
  final Databases _databases;

  StoreService(this._databases);

  Future<List<Store>> getStores({
    int limit = 20,
    int offset = 0,
    double? userLat,
    double? userLon,
    String? zoneId,
  }) async {
    try {
      final List<String> queries = [
        Query.limit(limit),
        Query.offset(offset),
        Query.orderAsc('name'),
      ];

      // إضافة شرط الفلترة على zoneId مباشرة في استعلام قاعدة البيانات
      if (zoneId != null && zoneId.isNotEmpty) {
        queries.add(Query.equal('zoneId', zoneId));
      }

      final response = await _databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'Stores',
        queries: queries,
      );

      // تحويل المستندات إلى كائنات Store
      final stores = response.documents.map((doc) {
        final store = Store.fromMap(doc.data);

        // حساب المسافة إذا كانت الإحداثيات متوفرة
        if (userLat != null && userLon != null) {
          store.distance = _calculateDistance(
            userLat,
            userLon,
            store.latitude,
            store.longitude,
          );
        }

        return store;
      }).toList();

      // ترتيب المتاجر حسب المسافة إذا كانت متوفرة
      if (userLat != null && userLon != null) {
        stores.sort((a, b) {
          final aDistance = a.distance ?? double.infinity;
          final bDistance = b.distance ?? double.infinity;
          return aDistance.compareTo(bDistance);
        });
      }

      return stores;
    } catch (e) {
      debugPrint('❌ Error fetching stores: $e');
      throw Exception(
        'فشل في تحميل المتاجر. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
      );
    }
  }

  // 🔹 الدالة الجديدة: لجلب المتجر بمعرفه
  Future<Store?> getStoreById(String storeId) async {
    try {
      final response = await _databases.getDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Stores',
        documentId: storeId,
      );
      return Store.fromMap(response.data);
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        debugPrint('❌ Store not found with ID: $storeId');
        return null; // Return null if the document does not exist
      }
      debugPrint('❌ Error fetching store by ID: $e');
      return null;
    } catch (e) {
      debugPrint('❌ An unexpected error occurred: $e');
      return null;
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'appwrite_service.dart';
import 'store_model.dart'; // تأكد من وجود ملف store_model.dart

class ProductService {
  final Databases _databases;

  ProductService(this._databases);

  // 🚀 دالة موحدة لجلب المنتجات بناءً على معرف المتجر والتصنيف الاختياري
  Future<List<Product>> getProducts({
    required String storeId,
    String? categoryId,
    int limit = 100, // حد معقول للتقسيم الصفحي
    int offset = 0,
  }) async {
    try {
      final queries = <String>[
        Query.equal('storeId', storeId),
        Query.limit(limit),
        Query.offset(offset),
      ];

      // إضافة شرط التصنيف فقط إذا تم تمريره
      if (categoryId != null && categoryId.isNotEmpty) {
        queries.add(Query.equal('categoryId', categoryId));
      }

      final response = await _databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'Products',
        queries: queries,
      );

      return response.documents
          .map((doc) => Product.fromMap(doc.data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      throw Exception('فشل في تحميل المنتجات');
    }
  }
}

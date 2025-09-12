import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static late final Client client;
  static late final Databases databases;
  static late final Account account;
  static late final Storage storage;

  /// تهيئة Appwrite
  /// يجب استدعاؤها مرة واحدة عند بدء التطبيق
  static Future<void> init() async {
    try {
      // تهيئة الـ Client وربطه بمشروع Appwrite
      client = Client()
          .setEndpoint('https://fra.cloud.appwrite.io/v1') // رابط السيرفر
          .setProject('6887ee78000e74d711f1'); // معرف المشروع

      // تهيئة الخدمات
      databases = Databases(client);
      account = Account(client);
      storage = Storage(client);

      // 🟢 تأكد من وجود Collection المندوبين
      print('✅ تم تهيئة Appwrite بنجاح');
      print('Databases جاهزة: ${databases}');
      print('Storage جاهز: ${storage}');
      print('Account جاهز: ${account}');
    } catch (e) {
      print('❌ فشل تهيئة Appwrite: $e');
      rethrow;
    }
  }
}

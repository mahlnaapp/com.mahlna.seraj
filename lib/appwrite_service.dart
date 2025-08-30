import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static late final Client client;
  static late final Databases databases;
  static late final Account account;
  static late final Storage storage;

  static Future<void> init() async {
    try {
      client = Client()
          .setEndpoint(
            'https://fra.cloud.appwrite.io/v1',
          ) // استبدل برابط السيرفر الخاص بك
          .setProject('6887ee78000e74d711f1'); // استبدل بمعرف المشروع الخاص بك

      // تهيئة جميع الخدمات المطلوبة
      databases = Databases(client);
      account = Account(client);
      storage = Storage(client);

      print('تم تهيئة Appwrite بنجاح');
    } catch (e) {
      print('فشل تهيئة Appwrite: $e');
      rethrow;
    }
  }
}

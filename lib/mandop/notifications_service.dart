// أضف هذا الكود في ملف notifications_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// يجب أن يكون هذا المتغير متاحًا للجميع، لذا يمكن أن يكون في نفس الملف أو كمتغير خارجي
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Initializes local notification settings
Future<void> initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettings = InitializationSettings(
    android: androidSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'orders_channel',
    'طلبات جديدة',
    description: 'إشعارات الطلبات الجديدة',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestPermission();
}

extension on AndroidFlutterLocalNotificationsPlugin? {
  Future<void> requestPermission() async {}
}

Future<void> showNewOrderNotification() async {
  const androidDetails = AndroidNotificationDetails(
    'orders_channel',
    'طلبات',
    channelDescription: 'إشعارات الطلبات الجديدة',
    importance: Importance.max,
    priority: Priority.high,
  );
  const platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    'لديك طلبية جديدة',
    'تمت إضافة طلب جديد في قائمة الطلبات الجاهزة للتوصيل.',
    platformDetails,
  );
}

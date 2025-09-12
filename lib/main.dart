import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appwrite/appwrite.dart';

import 'cart_provider.dart';
import 'orders_provider.dart';
import 'onboarding_screen.dart';
import 'location_screen.dart';
import 'delivery_screen.dart';
import 'store_screen.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'orders_screen.dart';
import 'appwrite_service.dart';
import 'store_service.dart';
import 'order_service.dart';
import 'settings_screen.dart' hide MandopLoginScreen;

// التاجر
import 'tajer/login_screen.dart';
import 'tajer/merchant_dashboard.dart';
import 'tajer/merchant_provider.dart';

// المندوب
import 'mandop/login_screen.dart';
import 'mandop/delivery_provider.dart';
import 'mandop/main_delivery_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppwriteService.init();

  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  final storedStoreId = prefs.getString('storeId');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(
          create: (_) => DeliveryProvider(
            AppwriteService.databases,
            AppwriteService.client,
          ),
        ),
        Provider(create: (_) => StoreService(AppwriteService.databases)),
        Provider(create: (_) => OrderService(AppwriteService.databases)),
        if (storedStoreId != null)
          ChangeNotifierProvider(
            create: (_) => MerchantProvider(
              AppwriteService.databases,
              AppwriteService.storage,
              storedStoreId,
            ),
          ),
      ],
      child: MyApp(
        showOnboarding: !seenOnboarding,
        initialStoreId: storedStoreId,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  final String? initialStoreId;
  const MyApp({super.key, required this.showOnboarding, this.initialStoreId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق محلنا',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      initialRoute: showOnboarding ? '/' : '/location',
      routes: {
        // زبون
        '/': (context) => const OnboardingAuthScreen(),
        '/location': (context) => const LocationScreen(),
        '/delivery': (context) => const DeliveryScreen(deliveryCity: "الموصل"),
        '/store': (context) => StoreScreen(storeName: "متجر", storeId: "1"),
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) {
          final total = Provider.of<CartProvider>(
            context,
            listen: false,
          ).totalPrice;
          return CheckoutScreen(totalAmount: total);
        },
        '/orders': (context) => const OrdersScreen(),
        '/settings': (context) => const SettingsScreen(),

        // التاجر
        '/merchant-login': (context) => LoginScreen(
          databases: AppwriteService.databases,
          storage: AppwriteService.storage,
        ),
        '/merchant-dashboard': (context) {
          if (initialStoreId != null) {
            return MerchantDashboard(
              databases: AppwriteService.databases,
              storage: AppwriteService.storage,
              initialTabIndex: 2,
            );
          } else {
            return LoginScreen(
              databases: AppwriteService.databases,
              storage: AppwriteService.storage,
            );
          }
        },

        // المندوب
        '/delivery-login': (context) => MandopLoginScreen(
          databases: AppwriteService.databases,
          storage: AppwriteService.storage,
        ),
        '/mandop-dashboard': (context) => const MainDeliveryScreen(zoneId: '1'),
      },
    );
  }
}

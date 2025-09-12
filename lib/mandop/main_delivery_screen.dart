// أضف هذا الكود في ملف screens/main_delivery_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mandop/delivery_provider.dart';
import '../mandop/orders_screen.dart';
import '../mandop/dashboard_screen.dart';

class MainDeliveryScreen extends StatefulWidget {
  final String zoneId;
  const MainDeliveryScreen({super.key, required this.zoneId});

  @override
  State<MainDeliveryScreen> createState() => _MainDeliveryScreenState();
}

class _MainDeliveryScreenState extends State<MainDeliveryScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<DeliveryProvider>(
        context,
        listen: false,
      ).loadAllOrders(zoneId: widget.zoneId),
    );
    Future.microtask(
      () => Provider.of<DeliveryProvider>(
        context,
        listen: false,
      ).startRealtimeListener(zoneId: widget.zoneId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context);

    final List<Widget> _screens = [
      OrdersScreen(
        orders: deliveryProvider.readyOrders,
        status: 'جاهزة للتوصيل',
        zoneId: widget.zoneId,
      ),
      OrdersScreen(
        orders: deliveryProvider.inProgressOrders,
        status: 'قيد التوصيل',
        zoneId: widget.zoneId,
      ),
      OrdersScreen(
        orders: deliveryProvider.completedOrders,
        status: 'تم التسليم',
        zoneId: widget.zoneId,
      ),
      const DashboardScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات التوصيل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                deliveryProvider.loadAllOrders(zoneId: widget.zoneId),
          ),
        ],
      ),
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return _screens[_currentIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'جاهزة للتوصيل',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'قيد التوصيل',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'مكتملة',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'اللوحة'),
        ],
      ),
    );
  }
}

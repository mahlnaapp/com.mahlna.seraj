// File: checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appwrite/appwrite.dart';
import 'cart_provider.dart';
import 'delivery_screen.dart';
import 'orders_provider.dart';
import 'order_model.dart';
import 'order_service.dart';
import 'appwrite_service.dart';
import 'order_item_model.dart';

class CheckoutScreen extends StatefulWidget {
  final double totalAmount;
  final String? zoneId;

  const CheckoutScreen({super.key, required this.totalAmount, this.zoneId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _landmarkController = TextEditingController();

  final Databases _databases = AppwriteService.databases;
  List<dynamic> _neighborhoods = [];
  String? _selectedNeighborhood;
  bool _isLoadingNeighborhoods = true;

  @override
  void initState() {
    super.initState();
    _loadSavedUserInfo(); // 🔹 تحميل المعلومات المحفوظة
    _fetchNeighborhoods();
  }

  // 🔹 تحميل البيانات المحفوظة من SharedPreferences
  Future<void> _loadSavedUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('checkout_name') ?? '';
      _phoneController.text = prefs.getString('checkout_phone') ?? '';
      _notesController.text = prefs.getString('checkout_notes') ?? '';
      _landmarkController.text = prefs.getString('checkout_landmark') ?? '';
    });
  }

  // 🔹 حفظ البيانات في SharedPreferences
  Future<void> _saveUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('checkout_name', _nameController.text);
    await prefs.setString('checkout_phone', _phoneController.text);
    await prefs.setString('checkout_notes', _notesController.text);
    await prefs.setString('checkout_landmark', _landmarkController.text);
  }

  Future<void> _fetchNeighborhoods() async {
    if (widget.zoneId == null || widget.zoneId!.isEmpty) {
      setState(() {
        _isLoadingNeighborhoods = false;
      });
      return;
    }

    try {
      final response = await _databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'zoneid',
        queries: [Query.equal('name', widget.zoneId)],
      );

      if (response.documents.isNotEmpty) {
        final zone = response.documents.first.data;
        _neighborhoods = (zone['neighborhoods'] as List<dynamic>? ?? [])
            .map((name) => {'name': name})
            .toList();

        if (_neighborhoods.isNotEmpty) {
          _selectedNeighborhood ??= _neighborhoods.first['name'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching neighborhoods: $e');
    } finally {
      setState(() {
        _isLoadingNeighborhoods = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الطلب'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('معلومات التوصيل'),
            _buildDeliveryForm(),
            const SizedBox(height: 24),
            _buildSectionTitle('طريقة الدفع'),
            _buildPaymentMethods(),
            const SizedBox(height: 24),
            _buildOrderSummary(cartProvider),
            const SizedBox(height: 32),
            _buildConfirmButton(context, cartProvider),
          ],
        ),
      ),
    );
  }

  double _calculateDeliveryFee(double total) {
    if (total <= 2500) return 250;
    if (total <= 10000) return 500;
    if (total < 20000) return 1000;
    return ((total ~/ 10000) * 1000).toDouble();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDeliveryForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _isLoadingNeighborhoods
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'المنطقة',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedNeighborhood,
                    items: _neighborhoods.map((neighborhood) {
                      return DropdownMenuItem<String>(
                        value: neighborhood['name'],
                        child: Text(neighborhood['name']),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedNeighborhood = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'الرجاء اختيار منطقة' : null,
                  ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _landmarkController,
              decoration: const InputDecoration(
                labelText: 'أقرب نقطة دالة',
                prefixIcon: Icon(Icons.location_pin),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات إضافية (اختياري)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            RadioListTile(
              title: const Text('الدفع نقداً عند الاستلام'),
              value: 'cash',
              groupValue: 'cash',
              onChanged: (value) {},
              activeColor: Colors.orange,
            ),
            const Divider(height: 1),
            RadioListTile(
              title: const Text('الدفع الإلكتروني'),
              value: 'online',
              groupValue: 'cash',
              onChanged: (value) {},
              activeColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    final deliveryFee = _calculateDeliveryFee(cart.totalPrice);
    final totalWithFee = cart.totalPrice + deliveryFee;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow(
              'المجموع',
              NumberFormat.currency(
                symbol: "د.ع",
                decimalDigits: 0,
              ).format(cart.totalPrice),
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'رسوم التوصيل',
              NumberFormat.currency(
                symbol: "د.ع",
                decimalDigits: 0,
              ).format(deliveryFee),
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'الإجمالي',
              NumberFormat.currency(
                symbol: "د.ع",
                decimalDigits: 0,
              ).format(totalWithFee),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.orange : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, CartProvider cart) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleOrderConfirmation(context, cart),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('تأكيد الطلب', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Future<void> _handleOrderConfirmation(
    BuildContext context,
    CartProvider cart,
  ) async {
    final name = _nameController.text;
    final phone = _phoneController.text;
    final landmark = _landmarkController.text;
    final address =
        'المنطقة: $_selectedNeighborhood, أقرب نقطة دالة: $landmark';

    if (name.isEmpty ||
        phone.isEmpty ||
        _selectedNeighborhood == null ||
        landmark.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء ملء جميع الحقول المطلوبة')),
        );
      }
      return;
    }

    await _saveUserInfo(); // 🔹 حفظ البيانات قبل تأكيد الطلب

    final confirmed = await _showConfirmationDialog(context);
    if (!confirmed) return;
    if (!context.mounted) return;

    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    final orderService = OrderService(AppwriteService.databases);

    final isMultiStore = cart.uniqueStoreIds.length > 1;
    final orderItems = cart.items
        .map(
          (cartItem) => OrderItem(
            productId: cartItem.productId,
            name: cartItem.name,
            price: cartItem.price,
            quantity: cartItem.quantity,
            image: cartItem.image,
            storeId: cartItem.storeId,
            storeName: cartItem.storeName,
          ),
        )
        .toList();

    final deliveryFee = _calculateDeliveryFee(cart.totalPrice);
    final totalWithFee = cart.totalPrice + deliveryFee;

    final newOrder = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user_id',
      customerName: name,
      orderDate: DateTime.now(),
      totalAmount: totalWithFee,
      status: 'جاهزة للتوصيل',
      deliveryAddress: address,
      phone: phone,
      items: orderItems,
      isMultiStore: isMultiStore,
      storeName: isMultiStore ? null : cart.items.first.storeName,
      storeId: isMultiStore ? null : cart.items.first.storeId,
      zoneId: widget.zoneId,
    );

    try {
      await orderService.createOrder(newOrder);
      if (context.mounted) {
        ordersProvider.addOrder(newOrder);
        cart.clearCart();

        final String? currentZoneId = cart.selectedZoneId;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DeliveryScreen(deliveryCity: "الموصل", zoneId: currentZoneId),
          ),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تأكيد طلبك بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إنشاء الطلب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الطلب'),
        content: const Text('هل أنت متأكد من طلبك؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

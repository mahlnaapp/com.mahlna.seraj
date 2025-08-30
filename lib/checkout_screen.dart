import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'cart_provider.dart';
import 'delivery_screen.dart';
import 'orders_provider.dart';
import 'order_model.dart';
import 'order_service.dart';
import 'appwrite_service.dart';
import 'order_item_model.dart';

class CheckoutScreen extends StatelessWidget {
  final double totalAmount;

  const CheckoutScreen({super.key, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الطلب'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('معلومات التوصيل'),
            _buildDeliveryForm(
              nameController,
              phoneController,
              addressController,
              notesController,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('طريقة الدفع'),
            _buildPaymentMethods(),
            const SizedBox(height: 24),
            _buildOrderSummary(cartProvider),
            const SizedBox(height: 32),
            _buildConfirmButton(
              context,
              cartProvider,
              nameController,
              phoneController,
              addressController,
            ),
          ],
        ),
      ),
    );
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

  Widget _buildDeliveryForm(
    TextEditingController nameController,
    TextEditingController phoneController,
    TextEditingController addressController,
    TextEditingController notesController,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow(
              'المجموع',
              '${NumberFormat.currency(symbol: 'د.ع', decimalDigits: 0).format(cart.totalPrice)}',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow('رسوم التوصيل', 'مجاني'),
            const Divider(height: 24),
            _buildSummaryRow(
              'الإجمالي',
              '${NumberFormat.currency(symbol: 'د.ع', decimalDigits: 0).format(cart.totalPrice)}',
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

  Widget _buildConfirmButton(
    BuildContext context,
    CartProvider cart,
    TextEditingController nameController,
    TextEditingController phoneController,
    TextEditingController addressController,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleOrderConfirmation(
          context,
          cart,
          nameController.text,
          phoneController.text,
          addressController.text,
        ),
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
    String name,
    String phone,
    String address,
  ) async {
    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء ملء جميع الحقول المطلوبة')),
        );
      }
      return;
    }

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

    final newOrder = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user_id',
      customerName: name, // أرسل اسم الزبون هنا

      orderDate: DateTime.now(),
      totalAmount: cart.totalPrice,
      status: 'جاهزة للتوصيل',
      deliveryAddress: address,
      phone: phone,
      items: orderItems,
      isMultiStore: isMultiStore,
      storeName: isMultiStore ? null : cart.items.first.storeName,
      storeId: isMultiStore ? null : cart.items.first.storeId,
    );

    try {
      await orderService.createOrder(newOrder);
      if (context.mounted) {
        ordersProvider.addOrder(newOrder);
        cart.clearCart();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryScreen(deliveryCity: "الموصل"),
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

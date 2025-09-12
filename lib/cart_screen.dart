// File: cart_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'checkout_screen.dart';
import 'appwrite_service.dart';
import 'store_service.dart'; // 🔹 الخطوة 1: استيراد StoreService

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // 🔹 الخطوة 2: تعريف مثيل لـ StoreService
  late StoreService _storeService;

  @override
  void initState() {
    super.initState();
    // 🔹 الخطوة 3: تهيئة الخدمة باستخدام مثيل Databases من AppwriteService
    _storeService = StoreService(AppwriteService.databases);
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final uniqueStores = cartProvider.uniqueStoreIds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة التسوق'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmation(context, cartProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: cartProvider.items.isEmpty
                ? _buildEmptyCart()
                : ListView.builder(
                    itemCount: uniqueStores.length,
                    itemBuilder: (context, storeIndex) {
                      final storeId = uniqueStores[storeIndex];
                      final storeItems = cartProvider.getItemsByStore(storeId);
                      final firstItem = storeItems.first;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStoreHeader(firstItem.storeName),
                          ...storeItems.map((item) {
                            return _buildCartItem(context, item, cartProvider);
                          }).toList(),
                          _buildStoreSubtotal(
                            cartProvider.getSubtotalByStore(storeId),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          if (cartProvider.items.isNotEmpty)
            _buildCheckoutSection(context, cartProvider),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'سلة التسوق فارغة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreHeader(String storeName) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        storeName,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          NumberFormat.currency(
            symbol: 'د.ع',
            decimalDigits: 0,
          ).format(item.price),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                if (item.quantity > 1) {
                  cartProvider.updateQuantity(
                    item.productId,
                    item.quantity - 1,
                  );
                } else {
                  cartProvider.removeItem(item.productId);
                }
              },
            ),
            Text(
              item.quantity.toString(),
              style: const TextStyle(fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                cartProvider.updateQuantity(item.productId, item.quantity + 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSubtotal(double subtotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'المجموع الفرعي:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            NumberFormat.currency(
              symbol: 'د.ع',
              decimalDigits: 0,
            ).format(subtotal),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(
    BuildContext context,
    CartProvider cartProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الإجمالي:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                cartProvider.formattedTotalPrice,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (cartProvider.items.isEmpty) return;

                final storeId = cartProvider.items.first.storeId;

                // 🔹 الخطوة 4: استخدام مثيل الخدمة لاستدعاء الدالة الجديدة
                final store = await _storeService.getStoreById(storeId);
                final zoneId = store?.zoneId;

                if (zoneId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutScreen(
                        totalAmount: cartProvider.totalPrice,
                        zoneId: zoneId,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تعذر تحديد المنطقة. يرجى المحاولة مرة أخرى.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('تأكيد الطلب', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    CartProvider cartProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفريغ السلة'),
        content: const Text(
          'هل أنت متأكد من أنك تريد حذف جميع العناصر من السلة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              cartProvider.removeAllItems();
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

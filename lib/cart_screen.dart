import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
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
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              firstItem.storeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...storeItems.map(
                            (item) => _buildCartItem(item, cartProvider),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المجموع الجزئي:'),
                                Text(
                                  NumberFormat.currency(
                                    symbol: 'د.ع',
                                    decimalDigits: 0,
                                  ).format(
                                    cartProvider.getSubtotalByStore(storeId),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
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

  Widget _buildCartItem(CartItem item, CartProvider cartProvider) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        cartProvider.removeItem(item.productId);
      },
      child: Card(
        margin: const EdgeInsets.all(8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.image.isEmpty
                ? Icon(Icons.shopping_bag, size: 30, color: Colors.grey[600])
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.image,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.shopping_bag,
                        size: 30,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
          ),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${NumberFormat.currency(symbol: 'د.ع', decimalDigits: 0).format(item.price)} × ${item.quantity}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red,
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
                color: Colors.green,
                onPressed: () {
                  cartProvider.updateQuantity(
                    item.productId,
                    item.quantity + 1,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'سلة التسوق فارغة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'قم بإضافة بعض المنتجات لتظهر هنا',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('تصفح المتاجر', style: TextStyle(fontSize: 16)),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('المجموع:', style: TextStyle(fontSize: 16)),
              Text(
                cartProvider.formattedTotalPrice,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CheckoutScreen(totalAmount: cartProvider.totalPrice),
                  ),
                );
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

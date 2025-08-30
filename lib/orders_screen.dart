import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'order_model.dart';
import 'orders_provider.dart';
import 'store_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = Provider.of<OrdersProvider>(context).orders;

    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي السابقة'), centerTitle: true),
      body: orders.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: orders.length,
              itemBuilder: (context, index) =>
                  _buildOrderItem(orders[index], context),
            ),
    );
  }

  Widget _buildOrderItem(Order order, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order.isMultiStore)
                const Text(
                  'طلب متعدد المتاجر',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                )
              else if (order.storeName != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.storeName!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'yyyy/MM/dd - hh:mm:ss a',
                      ).format(order.orderDate),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: order.items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${item.name} (${item.storeName})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.items.length} عنصر | ${NumberFormat.currency(symbol: 'د.ع', decimalDigits: 0).format(order.totalAmount)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'تم الطلب في: ${DateFormat('hh:mm:ss a').format(order.orderDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  if (!order.isMultiStore && order.storeId != null)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreScreen(
                              storeName: order.storeName ?? 'المتجر',
                              storeId: order.storeId!,
                            ),
                          ),
                        );
                      },
                      child: const Text('إعادة الطلب'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list_alt, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'لا توجد طلبات سابقة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'سيتم عرض طلباتك هنا بعد إتمام الشراء',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

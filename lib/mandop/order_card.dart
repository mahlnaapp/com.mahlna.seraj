// أضف هذا الكود في ملف screens/widgets/order_card.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../mandop/delivery_provider.dart';
import '../mandop/models.dart';

class OrderCard extends StatefulWidget {
  final DeliveryOrder order;
  final String status;
  final String zoneId;

  const OrderCard({
    super.key,
    required this.order,
    required this.status,
    required this.zoneId,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  Future<void> _showCancelDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        int countdown = 5;
        bool isButtonEnabled = false;
        Timer? timer;

        return StatefulBuilder(
          builder: (context, setState) {
            if (timer == null) {
              timer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (countdown > 0) {
                  setState(() {
                    countdown--;
                  });
                } else {
                  setState(() {
                    isButtonEnabled = true;
                  });
                  t.cancel();
                }
              });
            }
            return AlertDialog(
              title: const Text('تأكيد الإلغاء'),
              content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
              actions: <Widget>[
                TextButton(
                  child: const Text('إلغاء'),
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  onPressed: isButtonEnabled
                      ? () {
                          timer?.cancel();
                          Navigator.of(dialogContext).pop();
                          final provider = Provider.of<DeliveryProvider>(
                            context,
                            listen: false,
                          );
                          provider.updateOrderStatus(
                            widget.order.id,
                            'ملغاة',
                            zoneId: widget.zoneId,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم إلغاء الطلب')),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isButtonEnabled
                        ? 'تأكيد الإلغاء'
                        : 'تأكيد الإلغاء ($countdown)',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = Provider.of<DeliveryProvider>(
      context,
      listen: false,
    );
    final currencyFormat = NumberFormat.currency(
      symbol: 'د.ع',
      decimalDigits: 0,
    );

    final Map<String, List<OrderItem>> itemsByStore = {};
    for (var item in widget.order.items) {
      if (!itemsByStore.containsKey(item.storeId)) {
        itemsByStore[item.storeId] = [];
      }
      itemsByStore[item.storeId]!.add(item);
    }

    final zoneId = widget.zoneId;

    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text('طلب #${widget.order.id.substring(0, 6)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الزبون: ${widget.order.customerName}'),
            Text(
              'التاريخ: ${DateFormat('yyyy/MM/dd - hh:mm a').format(widget.order.orderDate)}',
            ),
            Text('الحالة: ${widget.order.status}'),
            if (widget.order.status == 'تم التسليم' &&
                widget.order.deliveryAgentName != null)
              Text('المندوب: ${widget.order.deliveryAgentName}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تفاصيل الطلب:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...itemsByStore.entries.map((entry) {
                  final storeId = entry.key;
                  final storeItems = entry.value;
                  final storeName = storeItems.first.storeName;
                  final storeImage = deliveryProvider.getStoreImage(storeId);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (storeImage.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: storeImage,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.store, size: 30),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.store, size: 30),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: const Icon(Icons.store, size: 30),
                            ),
                          const SizedBox(width: 12),
                          Text(
                            storeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...storeItems.map((item) {
                        final productImage = deliveryProvider.getProductImage(
                          item.productId,
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              if (productImage.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: productImage,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.shopping_bag,
                                        size: 30,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.shopping_bag,
                                            size: 30,
                                          ),
                                        ),
                                  ),
                                )
                              else
                                Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.shopping_bag,
                                    size: 30,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity} × ${currencyFormat.format(item.price)}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 24),
                    ],
                  );
                }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الإجمالي:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(currencyFormat.format(widget.order.totalAmount)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'معلومات التوصيل:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('العنوان: ${widget.order.address}'),
                Text('الهاتف: ${widget.order.phone}'),
                const SizedBox(height: 16),
                if (widget.status == 'جاهزة للتوصيل')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            deliveryProvider.updateOrderStatus(
                              widget.order.id,
                              'قيد التوصيل',
                              zoneId: zoneId,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم بدء عملية التوصيل'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('بدء التوصيل'),
                        ),
                      ),
                    ],
                  ),
                if (widget.status == 'قيد التوصيل')
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          deliveryProvider.updateOrderStatus(
                            widget.order.id,
                            'تم التسليم',
                            zoneId: zoneId,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تأكيد التسليم')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('تم التسليم'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _showCancelDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('إلغاء الطلب'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

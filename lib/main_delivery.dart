import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Application constants for Appwrite configuration
class AppConstants {
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  static const String projectId = '6887ee78000e74d711f1';
  static const String databaseId = 'mahllnadb';
  static const String ordersCollectionId = 'orders';
  static const String agentsCollectionId = 'DeliveryAgents';
  static const String orderItemsCollectionId = 'OrderItems';
  static const String productsCollectionId = 'Products';
  static const String storesCollectionId = 'Stores';
}

/// Global instance for local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Initializes local notification settings
Future<void> initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettings = InitializationSettings(
    android: androidSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();

  final client = Client()
      .setEndpoint(AppConstants.endpoint)
      .setProject(AppConstants.projectId);
  final databases = Databases(client);

  runApp(
    ChangeNotifierProvider(
      create: (_) => DeliveryProvider(databases, client),
      child: const DeliveryApp(),
    ),
  );
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق المندوب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class DeliveryProvider with ChangeNotifier {
  final Databases _databases;
  final Client _client;
  late final RealtimeSubscription _subscription;

  List<DeliveryOrder> _readyOrders = [];
  List<DeliveryOrder> _inProgressOrders = [];
  List<DeliveryOrder> _completedOrders = [];
  bool _isLoading = false;
  final Map<String, String> _storeImages = {};
  final Map<String, String> _productImages = {};

  DeliveryProvider(this._databases, this._client) {
    loadAllOrders();
    _startRealtimeListener();
  }

  List<DeliveryOrder> get readyOrders => _readyOrders;
  List<DeliveryOrder> get inProgressOrders => _inProgressOrders;
  List<DeliveryOrder> get completedOrders => _completedOrders;
  bool get isLoading => _isLoading;

  String getStoreImage(String storeId) => _storeImages[storeId] ?? '';
  String getProductImage(String productId) => _productImages[productId] ?? '';

  Future<void> loadAllOrders() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.ordersCollectionId,
      );

      _readyOrders = [];
      _inProgressOrders = [];
      _completedOrders = [];
      _storeImages.clear();
      _productImages.clear();

      for (var doc in response.documents) {
        final order = DeliveryOrder(
          id: doc.$id,
          customerName: doc.data['customerName'] ?? 'N/A',
          phone: doc.data['phone'] ?? 'N/A',
          address: doc.data['deliveryAddress'] ?? 'N/A',
          totalAmount: (doc.data['totalAmount'] as num).toDouble(),
          orderDate: DateTime.parse(doc.data['orderDate']),
          status: doc.data['status'] ?? 'N/A',
        );

        final itemsResponse = await _databases.listDocuments(
          databaseId: AppConstants.databaseId,
          collectionId: AppConstants.orderItemsCollectionId,
          queries: [Query.equal('orderId', order.id)],
        );

        order.items = await Future.wait(
          itemsResponse.documents.map((itemDoc) async {
            if (!_productImages.containsKey(itemDoc.data['productId'])) {
              try {
                final product = await _databases.getDocument(
                  databaseId: AppConstants.databaseId,
                  collectionId: AppConstants.productsCollectionId,
                  documentId: itemDoc.data['productId'],
                );
                _productImages[itemDoc.data['productId']] =
                    product.data['image'] ?? '';
              } catch (e) {
                _productImages[itemDoc.data['productId']] = '';
              }
            }
            if (!_storeImages.containsKey(itemDoc.data['storeId'])) {
              try {
                final store = await _databases.getDocument(
                  databaseId: AppConstants.databaseId,
                  collectionId: AppConstants.storesCollectionId,
                  documentId: itemDoc.data['storeId'],
                );
                _storeImages[itemDoc.data['storeId']] =
                    store.data['image'] ?? '';
              } catch (e) {
                _storeImages[itemDoc.data['storeId']] = '';
              }
            }
            return OrderItem(
              productId: itemDoc.data['productId'],
              productName: itemDoc.data['name'],
              quantity: itemDoc.data['quantity'],
              price: (itemDoc.data['price'] as num).toDouble(),
              storeId: itemDoc.data['storeId'],
              storeName: itemDoc.data['storeName'],
            );
          }),
        );

        if (order.status == 'جاهزة للتوصيل') {
          _readyOrders.add(order);
        } else if (order.status == 'قيد التوصيل') {
          _inProgressOrders.add(order);
        } else if (order.status == 'تم التسليم') {
          _completedOrders.add(order);
        }
      }

      _readyOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      _inProgressOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      _completedOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startRealtimeListener() {
    final realtime = Realtime(_client);
    _subscription = realtime.subscribe([
      'databases.${AppConstants.databaseId}.collections.${AppConstants.ordersCollectionId}.documents',
    ]);

    _subscription.stream.listen((response) {
      if (response.events.contains(
        'databases.*.collections.*.documents.*.create',
      )) {
        _showNotification();
        loadAllOrders();
      }
    });
  }

  Future<void> _showNotification() async {
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

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.ordersCollectionId,
        documentId: orderId,
        data: {'status': newStatus},
      );
      await loadAllOrders();
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

class DeliveryOrder {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final double totalAmount;
  final DateTime orderDate;
  String status;
  List<OrderItem> items = [];

  DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
  });
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String storeId;
  final String storeName;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.storeId,
    required this.storeName,
  });
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late final Databases _databases;

  @override
  void initState() {
    super.initState();
    final client = Client()
        .setEndpoint(AppConstants.endpoint)
        .setProject(AppConstants.projectId);
    _databases = Databases(client);
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await _databases.listDocuments(
          databaseId: AppConstants.databaseId,
          collectionId: AppConstants.agentsCollectionId,
          queries: [
            Query.equal('agentName', _usernameController.text),
            Query.equal('agentPassword', _passwordController.text),
          ],
        );

        if (response.documents.isNotEmpty) {
          final androidImplementation = flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          await androidImplementation?.requestPermission();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainDeliveryScreen(),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('بيانات الدخول غير صحيحة')),
            );
          }
        }
      } catch (e) {
        debugPrint('Login Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء تسجيل الدخول')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دخول المندوب')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('تسجيل الدخول'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on AndroidFlutterLocalNotificationsPlugin? {
  Future<void> requestPermission() async {}
}

class MainDeliveryScreen extends StatefulWidget {
  const MainDeliveryScreen({super.key});

  @override
  State<MainDeliveryScreen> createState() => _MainDeliveryScreenState();
}

class _MainDeliveryScreenState extends State<MainDeliveryScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات التوصيل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => deliveryProvider.loadAllOrders(),
          ),
        ],
      ),
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<Widget> _screens = [
            OrdersScreen(orders: provider.readyOrders, status: 'جاهزة للتوصيل'),
            OrdersScreen(
              orders: provider.inProgressOrders,
              status: 'قيد التوصيل',
            ),
            OrdersScreen(
              orders: provider.completedOrders,
              status: 'تم التسليم',
            ),
          ];
          return _screens[_currentIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
        ],
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  final List<DeliveryOrder> orders;
  final String status;

  const OrdersScreen({super.key, required this.orders, required this.status});

  @override
  Widget build(BuildContext context) {
    return orders.isEmpty
        ? Center(child: Text('لا توجد طلبات $status'))
        : ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(order: order, status: status);
            },
          );
  }
}

class OrderCard extends StatefulWidget {
  final DeliveryOrder order;
  final String status;

  const OrderCard({super.key, required this.order, required this.status});

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
                          Provider.of<DeliveryProvider>(
                            context,
                            listen: false,
                          ).updateOrderStatus(widget.order.id, 'ملغاة');
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

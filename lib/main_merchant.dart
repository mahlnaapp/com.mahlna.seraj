// main_merchant.dart
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ===============
// 🔔 تهيئة الإشعارات المحلية
// =======================
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// =======================
// ✅ دالة Top-level لمعالجة إشعارات الـ background
// =======================
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint(
    "📩 Notification clicked in background: ${notificationResponse.payload}",
  );
}

// =======================
// ✅ دالة لمعالجة الـ payload في الـ foreground
// =======================
Future<void> handleNotificationPayload(String? payload) async {
  if (payload != null && payload.isNotEmpty) {
    debugPrint('📦 Notification payload: $payload');
    // TODO: هنا ضيف التنقل لصفحة معينة إذا تريد
  }
}

// =======================
// 🚀 نقطة البداية
// =======================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إعدادات Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // إعدادات iOS
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  // إعدادات لجميع المنصات
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  // ✅ ربط الـ handlers
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse details) {
      handleNotificationPayload(details.payload);
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
  // Initialize Appwrite Client
  final client = Client()
      .setEndpoint('https://fra.cloud.appwrite.io/v1')
      .setProject('6887ee78000e74d711f1');

  final databases = Databases(client);
  final storage = Storage(client);

  final prefs = await SharedPreferences.getInstance();
  final storedStoreId = prefs.getString('storeId');

  runApp(
    MerchantApp(
      databases: databases,
      storage: storage,
      initialStoreId: storedStoreId,
    ),
  );
}

class MerchantApp extends StatelessWidget {
  final Databases databases;
  final Storage storage;
  final String? initialStoreId;

  const MerchantApp({
    super.key,
    required this.databases,
    required this.storage,
    this.initialStoreId,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لوحة تحكم التاجر',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      // إضافة مفتاح لـ Navigator لسهولة التنقل
      navigatorKey: GlobalKey<NavigatorState>(),
      home: initialStoreId == null
          ? LoginScreen(databases: databases, storage: storage)
          : ChangeNotifierProvider(
              create: (_) =>
                  MerchantProvider(databases, storage, initialStoreId!),
              child: MerchantDashboard(
                databases: databases,
                storage: storage,
                initialTabIndex: 2, // 2 هي مؤشر صفحة الطلبات
              ),
            ),
    );
  }
}

// شاشة جديدة لعرض رسالة الدفع المستحق
class PaymentDueScreen extends StatelessWidget {
  const PaymentDueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابك غير نشط'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, color: Colors.red, size: 80),
              const SizedBox(height: 20),
              const Text(
                'يبدو أن اشتراكك قد انتهى. يرجى تجديد الاشتراك للوصول إلى لوحة التحكم.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // يمكنك إضافة منطق للانتقال إلى صفحة الدفع هنا.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('جاري الانتقال إلى صفحة الدفع...'),
                    ),
                  );
                },
                child: const Text('انتقل إلى الدفع'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final Databases databases;
  final Storage storage;

  const LoginScreen({
    super.key,
    required this.databases,
    required this.storage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final res = await widget.databases.listDocuments(
          databaseId: 'mahllnadb',
          collectionId: 'storesowner',
          queries: [
            Query.equal('stname', _nameController.text),
            Query.equal('stpass', _passController.text),
          ],
        );

        if (res.documents.isNotEmpty) {
          final storeData = res.documents.first.data;

          // تم إضافة هذا الكود لتقييد وصول التاجر
          final storeStatus =
              storeData['is_active'] ?? false; // قراءة قيمة is_active

          if (storeStatus) {
            final storeId = storeData['stid'] as String;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('storeId', storeId);

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => MerchantProvider(
                      widget.databases,
                      widget.storage,
                      storeId,
                    ),
                    child: MerchantDashboard(
                      databases: widget.databases,
                      storage: widget.storage,
                    ),
                  ),
                ),
              );
            }
          } else {
            // توجيه المستخدم إلى شاشة الدفع إذا كان الحساب غير نشط
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentDueScreen(),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('اسم المستخدم أو كلمة المرور غير صحيحة'),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Login Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ في تسجيل الدخول: ${e.toString()}')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دخول التاجر')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الرجاء إدخال اسم المستخدم' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passController,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الرجاء إدخال كلمة المرور' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('تسجيل الدخول'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class MerchantProvider with ChangeNotifier {
  final Databases _databases;
  final Storage _storage;
  final String _storeId;

  bool _isLoading = true;
  Store? _store;
  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  List<Order> _orders = [];

  MerchantProvider(this._databases, this._storage, this._storeId) {
    _init();
  }

  bool get isLoading => _isLoading;
  Store? get store => _store;
  List<Product> get products => _products;
  List<Order> get orders => _orders;
  List<ProductCategory> get categories => _categories;

  Future<void> _init() async {
    await _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // جلب بيانات المتجر
      final storeDoc = await _databases.getDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Stores',
        documentId: _storeId,
      );
      _store = Store.fromMap(storeDoc.data);

      // جلب بيانات المنتجات
      final productsRes = await _databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'Products',
        queries: [Query.equal('storeId', _storeId)],
      );
      _products = productsRes.documents
          .map((doc) => Product.fromMap(doc.data))
          .toList();

      // جلب بيانات التصنيفات
      final categoriesRes = await _databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'ProductCategories',
        queries: [Query.equal('storeId', _storeId), Query.orderAsc('order')],
      );
      _categories = categoriesRes.documents
          .map((doc) => ProductCategory.fromMap(doc.data))
          .toList();

      // جلب جميع عناصر الطلب الخاصة بهذا المتجر أولاً
      final orderItemsRes = await _databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'OrderItems',
        queries: [Query.equal('storeId', _storeId)],
      );

      // استخراج orderIds الفريدة
      final orderIds = orderItemsRes.documents
          .map((doc) => doc.data['orderId'] as String)
          .toSet()
          .toList();

      // جلب تفاصيل الطلبات دفعة واحدة باستخدام Query.equal و Query.limit
      final ordersRes = await _databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'Orders',
        queries: [
          Query.equal('\$id', orderIds),
          Query.orderDesc('\$createdAt'),
          Query.limit(100),
        ],
      );

      _orders.clear();
      for (final orderDoc in ordersRes.documents) {
        final order = Order.fromMap(orderDoc.data);
        final itemsForThisStore = orderItemsRes.documents
            .where((item) => item.data['orderId'] == order.id)
            .map((doc) => OrderItems.fromMap(doc.data))
            .toList();
        order.items = itemsForThisStore;
        order.totalAmount = itemsForThisStore.fold(
          0,
          (sum, item) => sum + (item.price * item.quantity),
        );
        _orders.add(order);
      }

      _orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading store data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await _loadStoreData();
  }

  Future<void> updateStoreStatus(bool isOpen) async {
    try {
      await _databases.updateDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Stores',
        documentId: _storeId,
        data: {'isOpen': isOpen},
      );
      _store!.isOpen = isOpen;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating store status: $e');
      rethrow;
    }
  }

  Future<void> updateStoreDetails({
    required String name,
    required String category,
    required double latitude,
    required double longitude,
    required String image,
  }) async {
    try {
      await _databases.updateDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Stores',
        documentId: _storeId,
        data: {
          'name': name,
          'category': category,
          'latitude': latitude,
          'longitude': longitude,
          'image': image,
        },
      );
      _store = _store!.copyWith(
        name: name,
        category: category,
        latitude: latitude,
        longitude: longitude,
        image: image,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating store details: $e');
      rethrow;
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      final newProduct = product.copyWith(storeId: _storeId);
      final res = await _databases.createDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Products',
        documentId: ID.unique(),
        data: newProduct.toMap(),
      );
      _products.add(Product.fromMap(res.data));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _databases.updateDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Products',
        documentId: product.id,
        data: product.toMap(),
      );
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> addCategory(String name) async {
    try {
      final newCategory = ProductCategory(
        id: ID.unique(),
        name: name,
        storeId: _storeId,
        order: _categories.length,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final res = await _databases.createDocument(
        databaseId: 'mahllnadb',
        collectionId: 'ProductCategories',
        documentId: newCategory.id,
        data: newCategory.toMap(),
      );

      _categories.add(ProductCategory.fromMap(res.data));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }
}

class MerchantDashboard extends StatefulWidget {
  final Databases databases;
  final Storage storage;
  final int? initialTabIndex;

  const MerchantDashboard({
    super.key,
    required this.databases,
    required this.storage,
    this.initialTabIndex,
  });

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  int _currentTabIndex = 0;
  RealtimeSubscription? subscription;

  @override
  void initState() {
    super.initState();
    if (widget.initialTabIndex != null) {
      _currentTabIndex = widget.initialTabIndex!;
    }
    _startRealtimeListener();
  }

  @override
  void dispose() {
    subscription?.close();
    super.dispose();
  }

  // دالة لبدء المستمع في الوقت الفعلي
  void _startRealtimeListener() {
    final storeId = Provider.of<MerchantProvider>(
      context,
      listen: false,
    ).store?.id;
    if (storeId == null) return;

    final realtime = Realtime(widget.databases.client);

    // الاشتراك في التغييرات لمجموعة الطلبات
    subscription = realtime.subscribe([
      'databases.mahllnadb.collections.Orders.documents',
    ]);

    // الاستماع للطلبات الجديدة فقط
    subscription!.stream.listen((response) {
      if (response.events.contains(
        'databases.mahllnadb.collections.Orders.documents.*.create',
      )) {
        final newOrderData = response.payload;
        // التحقق من أن الطلب الجديد يخص هذا المتجر
        if (newOrderData['storeId'] == storeId) {
          _showNewOrderNotification();
        }
      }
    });
  }

  // دالة لعرض الإشعار المحلي
  Future<void> _showNewOrderNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'new_order_channel',
      'طلبيات جديدة',
      channelDescription: 'إشعارات بوصول طلبيات جديدة للمتجر',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // معرف الإشعار
      'طلبية جديدة!',
      'لديك طلبية جديدة. يرجى مراجعة صفحة الطلبات.',
      notificationDetails,
      payload: 'new_order',
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('storeId');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MerchantApp(
            databases: widget.databases,
            storage: widget.storage,
            initialStoreId: null,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم التاجر'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<MerchantProvider>(
                context,
                listen: false,
              ).refreshData();
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Consumer<MerchantProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.store == null) {
            return const Center(child: Text('حدث خطأ في تحميل بيانات المتجر'));
          }

          return IndexedStack(
            index: _currentTabIndex,
            children: [
              _buildDashboardTab(provider),
              _buildProductsTab(provider),
              _buildOrdersTab(provider),
              _buildCategoriesTab(provider),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
          // تحديث البيانات عند الانتقال إلى صفحة الطلبات
          if (index == 2) {
            Provider.of<MerchantProvider>(context, listen: false).refreshData();
          }
        },
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'المنتجات',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'الطلبات'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'التصنيفات',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(MerchantProvider provider) {
    // ... الكود السابق
    final store = provider.store!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: store.image.isNotEmpty
                        ? NetworkImage(store.image)
                        : const AssetImage('assets/store_placeholder.png')
                              as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              store.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showEditStoreDialog(provider),
                            ),
                          ],
                        ),
                        Text(store.category),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Switch(
                              value: store.isOpen,
                              onChanged: (value) async {
                                try {
                                  await provider.updateStoreStatus(value);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value
                                            ? 'تم فتح المتجر'
                                            : 'تم إغلاق المتجر',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('حدث خطأ: ${e.toString()}'),
                                    ),
                                  );
                                }
                              },
                              activeColor: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(store.isOpen ? 'مفتوح' : 'مغلق'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'المنتجات',
                provider.products.length.toString(),
                Icons.shopping_bag,
                Colors.blue,
              ),
              _buildStatCard(
                'الطلبات',
                provider.orders.length.toString(),
                Icons.list_alt,
                Colors.green,
              ),
              _buildStatCard(
                'التصنيفات',
                provider.categories.length.toString(),
                Icons.category,
                Colors.purple,
              ),
              _buildStatCard(
                'المبيعات',
                '${provider.orders.fold(0, (int sum, order) => sum + order.totalAmount.toInt())} د.ع',
                Icons.attach_money,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'آخر الطلبات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (provider.orders.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('لا توجد طلبات حديثة'),
              ),
            )
          else
            ...provider.orders.take(3).map((order) => _buildOrderCard(order)),
        ],
      ),
    );
  }

  Widget _buildProductsTab(MerchantProvider provider) {
    // ... الكود السابق
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddProductDialog(provider),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              final product = provider.products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: product.image.isNotEmpty
                      ? Image.network(product.image, width: 50, height: 50)
                      : const Icon(Icons.shopping_bag),
                  title: Text(product.name),
                  subtitle: Text('${product.price} د.ع'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _showEditProductDialog(provider, product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteProduct(provider, product.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab(MerchantProvider provider) {
    // ... الكود السابق
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث عن طلب...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: provider.orders.length,
            itemBuilder: (context, index) {
              final order = provider.orders[index];

              // حساب الإجمالي الجزئي للمتجر الحالي فقط
              double storeSubtotal = order.items.fold(
                0,
                (sum, item) => sum + (item.price * item.quantity),
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text(
                    'طلب #${order.id.substring(0, 6)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الاسم: ${order.customerName}'),
                      Text('الهاتف: ${order.phone}'),
                      Text('العنوان: ${order.deliveryAddress}'),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المنتجات المطلوبة:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      item.image.isNotEmpty
                                          ? Image.network(
                                              item.image,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.shopping_bag,
                                              ),
                                            ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'السعر: ${NumberFormat.currency(symbol: 'د.ع', decimalDigits: 0).format(item.price)}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              'الكمية: ${item.quantity}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              'المجموع: ${NumberFormat.currency(symbol: 'د.ع', decimalDigits: 0).format(item.price * item.quantity)}',
                                              style: const TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'إجمالي منتجات متجرك: ${NumberFormat.currency(symbol: 'د.ع', decimalDigits: 0).format(storeSubtotal)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab(MerchantProvider provider) {
    // ... الكود السابق
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'اسم التصنيف الجديد',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  controller: TextEditingController(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddCategoryDialog(provider),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              return Card(
                key: Key(category.id),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(category.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _showEditCategoryDialog(provider, category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCategory(provider, category.id),
                      ),
                    ],
                  ),
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              // TODO: Implement reordering logic
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب #${order.id.substring(0, 6)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${order.totalAmount} د.ع',
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${order.items.length} منتج'),
            const SizedBox(height: 8),
            ...order.items
                .take(2)
                .map(
                  (item) => Text(
                    '${item.name} × ${item.quantity}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
            if (order.items.length > 2)
              const Text('...وغيرها', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                Text(
                  DateFormat('yyyy/MM/dd').format(order.orderDate),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditStoreDialog(MerchantProvider provider) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: provider.store!.name);
    final imageController = TextEditingController(text: provider.store!.image);
    String selectedCategory = provider.store!.category;
    double? latitude = provider.store!.latitude;
    double? longitude = provider.store!.longitude;

    // Categories list, you can add more here
    final List<String> categories = [
      'سوبرماركت',
      'أفران',
      'مواد غذائية',
      'مطاعم',
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل بيانات المتجر'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المتجر',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'تصنيف المتجر',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async => _uploadImage(
                                ImageSource.gallery,
                                imageController,
                              ),
                              child: const Text('صورة من المعرض'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async => _uploadImage(
                                ImageSource.camera,
                                imageController,
                              ),
                              child: const Text('صورة من الكاميرا'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (imageController.text.isNotEmpty)
                          Image.network(
                            imageController.text,
                            height: 100,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error, color: Colors.red);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('الموقع الجغرافي'),
                      subtitle: Text(
                        'Lat: ${latitude?.toStringAsFixed(4) ?? 'غير محدد'}, Lon: ${longitude?.toStringAsFixed(4) ?? 'غير محدد'}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: () async {
                          final permissionStatus = await permission_handler
                              .Permission
                              .location
                              .request();
                          if (permissionStatus.isGranted) {
                            try {
                              final position =
                                  await Geolocator.getCurrentPosition(
                                    desiredAccuracy: LocationAccuracy.high,
                                  );
                              setState(() {
                                latitude = position.latitude;
                                longitude = position.longitude;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم تحديد الموقع بنجاح!'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('خطأ في تحديد الموقع: $e'),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم رفض إذن الوصول للموقع.'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                if (latitude == null || longitude == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('الرجاء تحديد الموقع الجغرافي.'),
                    ),
                  );
                  return;
                }
                try {
                  await provider.updateStoreDetails(
                    name: nameController.text,
                    category: selectedCategory,
                    latitude: latitude!,
                    longitude: longitude!,
                    image: imageController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث بيانات المتجر بنجاح'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadImage(
    ImageSource source,
    TextEditingController controller,
  ) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile == null) return;

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        pickedFile.path + '_compressed.jpg',
        quality: 70,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressedFile == null) return;

      final fileSize = await compressedFile.length() / 1024;
      if (fileSize > 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حجم الصورة كبير جداً (يجب أن يكون أقل من 500KB)'),
          ),
        );
        return;
      }

      final provider = Provider.of<MerchantProvider>(context, listen: false);
      const bucketId = 'images';
      final result = await provider._storage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: compressedFile.path),
      );

      final imageUrl =
          'https://fra.cloud.appwrite.io/v1/storage/buckets/$bucketId/files/${result.$id}/view?project=6887ee78000e74d711f1';

      controller.text = imageUrl;
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في رفع الصورة: ${e.toString()}')),
      );
      debugPrint('Error uploading image: $e');
    }
  }

  Future<void> _showAddProductDialog(MerchantProvider provider) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    final imageController = TextEditingController();
    String? selectedCategoryId;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة منتج جديد'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المنتج'),
                  validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'السعر'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                  maxLines: 3,
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async => _uploadImage(
                            ImageSource.gallery,
                            imageController,
                          ),
                          child: const Text('من المعرض'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async =>
                              _uploadImage(ImageSource.camera, imageController),
                          child: const Text('الكاميرا'),
                        ),
                      ],
                    ),
                    if (imageController.text.isNotEmpty)
                      Image.network(
                        imageController.text,
                        height: 100,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error, color: Colors.red);
                        },
                      ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  items: provider.categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) => selectedCategoryId = value,
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  final newProduct = Product(
                    id: ID.unique(),
                    name: nameController.text,
                    description: descController.text,
                    price: double.parse(priceController.text),
                    categoryId:
                        selectedCategoryId ?? provider.categories.first.id,
                    isAvailable: true,
                    isPopular: false,
                    hasOffer: false,
                    image: imageController.text,
                    storeId: provider.store!.id,
                  );

                  await provider.addProduct(newProduct);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إضافة المنتج بنجاح')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProductDialog(
    MerchantProvider provider,
    Product product,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final descController = TextEditingController(text: product.description);
    final imageController = TextEditingController(text: product.image);
    String? selectedCategoryId = product.categoryId;
    bool isAvailable = product.isAvailable;
    bool isPopular = product.isPopular;
    bool hasOffer = product.hasOffer;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المنتج'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المنتج'),
                  validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'السعر'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                  maxLines: 3,
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async => _uploadImage(
                            ImageSource.gallery,
                            imageController,
                          ),
                          child: const Text('من المعرض'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async =>
                              _uploadImage(ImageSource.camera, imageController),
                          child: const Text('الكاميرا'),
                        ),
                      ],
                    ),
                    if (imageController.text.isNotEmpty)
                      Image.network(
                        imageController.text,
                        height: 100,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error, color: Colors.red);
                        },
                      ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  items: provider.categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) => selectedCategoryId = value,
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                ),
                SwitchListTile(
                  title: const Text('متوفر'),
                  value: isAvailable,
                  onChanged: (value) {
                    setState(() {
                      isAvailable = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('شائع'),
                  value: isPopular,
                  onChanged: (value) {
                    setState(() {
                      isPopular = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('لديه عرض'),
                  value: hasOffer,
                  onChanged: (value) {
                    setState(() {
                      hasOffer = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  final updatedProduct = Product(
                    id: product.id,
                    name: nameController.text,
                    description: descController.text,
                    price: double.parse(priceController.text),
                    categoryId: selectedCategoryId ?? product.categoryId,
                    isAvailable: isAvailable,
                    isPopular: isPopular,
                    hasOffer: hasOffer,
                    image: imageController.text,
                    storeId: product.storeId,
                  );

                  await provider.updateProduct(updatedProduct);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث المنتج بنجاح')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(
    MerchantProvider provider,
    String productId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await provider._databases.deleteDocument(
          databaseId: 'mahllnadb',
          collectionId: 'Products',
          documentId: productId,
        );
        provider._products.removeWhere((p) => p.id == productId);
        provider.notifyListeners();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف المنتج بنجاح')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
      }
    }
  }

  Future<void> _showAddCategoryDialog(MerchantProvider provider) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة تصنيف جديد'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'اسم التصنيف'),
            validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await provider.addCategory(nameController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إضافة التصنيف بنجاح')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCategoryDialog(
    MerchantProvider provider,
    ProductCategory category,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category.name);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل التصنيف'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'اسم التصنيف'),
            validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  final updatedCategory = ProductCategory(
                    id: category.id,
                    name: nameController.text,
                    storeId: category.storeId,
                    order: category.order,
                    isActive: category.isActive,
                    createdAt: category.createdAt,
                  );

                  await provider._databases.updateDocument(
                    databaseId: 'mahllnadb',
                    collectionId: 'ProductCategories',
                    documentId: category.id,
                    data: updatedCategory.toMap(),
                  );

                  final index = provider._categories.indexWhere(
                    (c) => c.id == category.id,
                  );
                  if (index != -1) {
                    provider._categories[index] = updatedCategory;
                    provider.notifyListeners();
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث التصنيف بنجاح')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(
    MerchantProvider provider,
    String categoryId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التصنيف'),
        content: const Text('هل أنت متأكد من حذف هذا التصنيف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await provider._databases.deleteDocument(
          databaseId: 'mahllnadb',
          collectionId: 'ProductCategories',
          documentId: categoryId,
        );
        provider._categories.removeWhere((c) => c.id == categoryId);
        provider.notifyListeners();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف التصنيف بنجاح')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
      }
    }
  }
}

class Store {
  final String id;
  final String name;
  final String category;
  final String image;
  bool isOpen;
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;
  double? distance;
  // تم إضافة هذا الحقل لتقييد وصول التاجر
  final bool is_active;

  Store({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.isOpen,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
    this.distance,
    required this.is_active,
  });

  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      id: map['\$id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      image: map['image'] ?? '',
      isOpen: map['isOpen'] ?? true,
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'],
      phone: map['phone'],
      // قراءة قيمة is_active من الخريطة، القيمة الافتراضية هي true
      is_active: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'image': image,
      'isOpen': isOpen,
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      'is_active': is_active,
    };
  }

  Store copyWith({
    String? name,
    String? category,
    double? latitude,
    double? longitude,
    String? image,
  }) {
    return Store(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      image: image ?? this.image,
      isOpen: isOpen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address,
      phone: phone,
      distance: distance,
      is_active: is_active,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  bool isAvailable;
  final bool isPopular;
  final bool hasOffer;
  final String image;
  final String storeId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.isAvailable,
    required this.isPopular,
    required this.hasOffer,
    required this.image,
    required this.storeId,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['\$id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      categoryId: map['categoryId'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      isPopular: map['isPopular'] ?? false,
      hasOffer: map['hasOffer'] ?? false,
      image: map['image'] ?? '',
      storeId: map['storeId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'isAvailable': isAvailable,
      'isPopular': isPopular,
      'hasOffer': hasOffer,
      'image': image,
      'storeId': storeId,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    bool? isAvailable,
    bool? isPopular,
    bool? hasOffer,
    String? image,
    String? storeId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      isAvailable: isAvailable ?? this.isAvailable,
      isPopular: isPopular ?? this.isPopular,
      hasOffer: hasOffer ?? this.hasOffer,
      image: image ?? this.image,
      storeId: storeId ?? this.storeId,
    );
  }
}

class ProductCategory {
  final String id;
  final String name;
  final String storeId;
  final int order;
  final bool isActive;
  final DateTime createdAt;

  ProductCategory({
    required this.id,
    required this.name,
    required this.storeId,
    required this.order,
    required this.isActive,
    required this.createdAt,
  });

  factory ProductCategory.fromMap(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['\$id'] ?? '',
      name: map['name'] ?? '',
      storeId: map['storeId'] ?? '',
      order: map['order']?.toInt() ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'storeId': storeId,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Order {
  final String id;
  final String userId;
  final String customerName;
  final DateTime orderDate;
  double totalAmount;
  final String status;
  final String deliveryAddress;
  final String phone;
  List<OrderItems> items;
  final bool isMultiStore;
  final String? storeName;
  final String? storeId;

  Order({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.phone,
    required this.items,
    required this.isMultiStore,
    this.storeName,
    this.storeId,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['\$id'] ?? '',
      userId: map['userId'] ?? '',
      customerName: map['customerName'] ?? '',
      orderDate: DateTime.parse(map['orderDate']),
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      status: map['status'] ?? '',
      deliveryAddress: map['deliveryAddress'] ?? '',
      phone: map['phone'] ?? '',
      items: [],
      isMultiStore: map['isMultiStore'] ?? false,
      storeName: map['storeName'],
      storeId: map['storeId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'customerName': customerName,
      'orderDate': orderDate.toIso8601String(),
      'totalAmount': totalAmount,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'phone': phone,
      'isMultiStore': isMultiStore,
      'storeName': storeName,
      'storeId': storeId,
    };
  }
}

class OrderItems {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String image;
  final String storeId;
  final String storeName;

  OrderItems({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    required this.storeId,
    required this.storeName,
  });

  factory OrderItems.fromMap(Map<String, dynamic> map) {
    return OrderItems(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 1,
      image: map['image'] ?? '',
      storeId: map['storeId'] ?? '',
      storeName: map['storeName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
      'storeId': storeId,
      'storeName': storeName,
    };
  }
}

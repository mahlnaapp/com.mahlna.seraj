import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/appwrite.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tajer/merchant_provider.dart';
import '../tajer/product.dart';
import '../tajer/order.dart';
import '../tajer/product_category.dart';
import 'store.dart' show Store;
// To navigate back to the main app

class MerchantDashboard extends StatefulWidget {
  final Databases databases;
  final Storage storage;
  final int? initialTabIndex;
  // تمت إضافة onLogout لتوجيه المستخدم لصفحة تسجيل الدخول
  final VoidCallback? onLogout;

  const MerchantDashboard({
    super.key,
    required this.databases,
    required this.storage,
    this.initialTabIndex,
    this.onLogout, // تمت إضافته
  });

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard>
    with SingleTickerProviderStateMixin {
  int _currentTabIndex = 0;
  RealtimeSubscription? subscription;

  final TextEditingController _productSearchController =
      TextEditingController();
  final TextEditingController _orderSearchController = TextEditingController();
  String _productSearchQuery = '';
  String _orderSearchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialTabIndex != null) {
      _currentTabIndex = widget.initialTabIndex!;
    }

    _productSearchController.addListener(() {
      setState(() {
        _productSearchQuery = _productSearchController.text;
      });
    });

    _orderSearchController.addListener(() {
      setState(() {
        _orderSearchQuery = _orderSearchController.text;
      });
    });

    _startRealtimeListener();
  }

  @override
  void dispose() {
    subscription?.close();
    _productSearchController.dispose();
    _orderSearchController.dispose();
    super.dispose();
  }

  void _startRealtimeListener() {
    final storeId = Provider.of<MerchantProvider>(
      context,
      listen: false,
    ).store?.id;
    if (storeId == null) return;

    final realtime = Realtime(widget.databases.client);

    subscription = realtime.subscribe([
      'databases.mahllnadb.collections.Orders.documents',
    ]);

    subscription!.stream.listen((response) {
      if (response.events.contains(
        'databases.mahllnadb.collections.Orders.documents.*.create',
      )) {
        // ... (No-op as per original code)
      }
    });
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
              _buildStoreTab(provider), // الصفحة الجديدة
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
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
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'المتجر'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(MerchantProvider provider) {
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
    final filteredProducts = provider.products.where((product) {
      return product.name.toLowerCase().contains(
        _productSearchQuery.toLowerCase(),
      );
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _productSearchController,
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
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: product.image.isNotEmpty
                      ? Image.network(
                          product.image,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
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
    final filteredOrders = provider.orders.where((order) {
      return order.customerName.toLowerCase().contains(
            _orderSearchQuery.toLowerCase(),
          ) ||
          order.phone.contains(_orderSearchQuery) ||
          order.id.toLowerCase().contains(_orderSearchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _orderSearchController,
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
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
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
    final TextEditingController categoryNameController =
        TextEditingController();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: categoryNameController,
                  decoration: InputDecoration(
                    hintText: 'اسم التصنيف الجديد',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  if (categoryNameController.text.isNotEmpty) {
                    try {
                      await provider.addCategory(categoryNameController.text);
                      categoryNameController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إضافة التصنيف بنجاح')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الرجاء إدخال اسم التصنيف')),
                    );
                  }
                },
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

  // دالة بناء صفحة معلومات المتجر الجديدة
  Widget _buildStoreTab(MerchantProvider provider) {
    final store = provider.store!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: store.image.isNotEmpty
                        ? NetworkImage(store.image)
                        : const AssetImage('assets/store_placeholder.png')
                              as ImageProvider,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    store.category,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Chip(
                        label: Text(store.isOpen ? 'مفتوح' : 'مغلق'),
                        backgroundColor: store.isOpen
                            ? Colors.green
                            : Colors.red,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(store.is_active ? 'نشط' : 'غير نشط'),
                        backgroundColor: store.is_active
                            ? Colors.blue
                            : Colors.orange,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'معلومات المتجر',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _buildInfoRow('معرف المتجر:', store.id),
                  _buildInfoRow('الهاتف:', store.phone ?? 'غير محدد'),
                  _buildInfoRow('العنوان:', store.address ?? 'غير محدد'),
                  _buildInfoRow('خط العرض:', store.latitude.toStringAsFixed(6)),
                  _buildInfoRow(
                    'خط الطول:',
                    store.longitude.toStringAsFixed(6),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showEditStoreInfoDialog(provider),
                          child: const Text('تعديل المعلومات'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إحصائيات المتجر',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'المنتجات',
                        provider.products.length.toString(),
                      ),
                      _buildStatItem(
                        'الطلبات',
                        provider.orders.length.toString(),
                      ),
                      _buildStatItem(
                        'التصنيفات',
                        provider.categories.length.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // إضافة أزرار الحذف والتسجيل خروج (مطلوب التحديث)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'إدارة الحساب',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    // هذا هو زر تسجيل الخروج
                    onPressed: _showLogoutConfirmation,
                    icon: const Icon(Icons.logout),
                    label: const Text('تسجيل خروج'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: () => _showDeleteAccountConfirmation(provider),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('حذف الحساب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  // دالة لعرض dialog لتعديل معلومات المتجر
  Future<void> _showEditStoreInfoDialog(MerchantProvider provider) async {
    final formKey = GlobalKey<FormState>();
    final store = provider.store!;

    final nameController = TextEditingController(text: store.name);
    final phoneController = TextEditingController(text: store.phone ?? '');
    final addressController = TextEditingController(text: store.address ?? '');
    final categoryController = TextEditingController(text: store.category);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل معلومات المتجر'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المتجر'),
                  validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'تصنيف المتجر'),
                  validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                  maxLines: 3,
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
                  // إنشاء كائن Store مع البيانات المحدثة
                  final updatedStore = Store(
                    id: store.id,
                    name: nameController.text,
                    category: categoryController.text,
                    image: store.image,
                    isOpen: store.isOpen,
                    latitude: store.latitude,
                    longitude: store.longitude,
                    address: addressController.text.isNotEmpty
                        ? addressController.text
                        : null,
                    phone: phoneController.text.isNotEmpty
                        ? phoneController.text
                        : null,
                    is_active: store.is_active,
                  );

                  // تحديث المتجر في قاعدة البيانات
                  await provider.databases.updateDocument(
                    databaseId: 'mahllnadb',
                    collectionId: 'Stores',
                    documentId: store.id,
                    data: updatedStore.toMap(),
                  );

                  // تحديث حالة التطبيق

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث معلومات المتجر بنجاح'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                    );
                  }
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // دالة لعرض تأكيد تسجيل الخروج (مضافة)
  // في دالة _showLogoutConfirmation، استبدل الكود الحالي بالكود التالي:
  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'تسجيل خروج',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      // مسح بيانات المتجر المحفوظة
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('storeId');

      // التوجيه إلى شاشة LocationScreen
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/location',
          (route) => false,
        );
      }
    }
  }

  // دالة لعرض تأكيد حذف الحساب (مضافة)
  Future<void> _showDeleteAccountConfirmation(MerchantProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حذف حسابك؟'),
            SizedBox(height: 8),
            Text(
              '⚠️ تحذير: هذا الإجراء لا يمكن التراجع عنه',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'سيتم حذف جميع بيانات متجرك بما في ذلك:',
              style: TextStyle(fontSize: 12),
            ),
            Text('• معلومات المتجر', style: TextStyle(fontSize: 12)),
            Text('• المنتجات والتصنيفات', style: TextStyle(fontSize: 12)),
            Text('• سجل الطلبات', style: TextStyle(fontSize: 12)),
            SizedBox(height: 8),
            Text(
              'لن تتمكن من الوصول إلى هذه البيانات مرة أخرى',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'حذف الحساب',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _deleteAccount(provider);
    }
  }

  // دالة حذف الحساب (مضافة)
  // استبدل دالة _deleteAccount الحالية بالكود التالي:
  Future<void> _deleteAccount(MerchantProvider provider) async {
    try {
      // إظهار loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري حذف الحساب...'),
              ],
            ),
          ),
        );
      }

      // 1. حذف جميع منتجات المتجر
      for (final product in provider.products) {
        await provider.databases.deleteDocument(
          databaseId: 'mahllnadb',
          collectionId: 'Products',
          documentId: product.id,
        );
      }

      // 2. حذف جميع تصنيفات المتجر
      for (final category in provider.categories) {
        await provider.databases.deleteDocument(
          databaseId: 'mahllnadb',
          collectionId: 'ProductCategories',
          documentId: category.id,
        );
      }

      // 3. حذف المتجر نفسه
      await provider.databases.deleteDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Stores',
        documentId: provider.store!.id,
      );

      // 4. مسح بيانات المتجر المحفوظة محلياً
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('storeId');

      // إغلاق dialog التحميل
      if (mounted) Navigator.pop(context);

      // إظهار رسالة نجاح
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الحساب بنجاح')));
      }

      // التوجيه إلى شاشة LocationScreen بعد الحذف
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/location',
          (route) => false,
        );
      }
    } catch (e) {
      // إغلاق dialog التحميل في حالة الخطأ
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حذف الحساب: ${e.toString()}')),
        );
      }
    }
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
    final List<String> categories = [
      'سوبرماركت',
      'البان واجبان',
      'أفران',
      'حلويات وكرزات',
      'مواد غذائية',
      'مطاعم',
      'عطارية',
      'مرطبات',
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
                                provider,
                              ),
                              child: const Text('صورة من المعرض'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async => _uploadImage(
                                ImageSource.camera,
                                imageController,
                                provider,
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
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم تحديد الموقع بنجاح!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('خطأ في تحديد الموقع: $e'),
                                  ),
                                );
                              }
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم رفض إذن الوصول للموقع.'),
                                ),
                              );
                            }
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
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث بيانات المتجر بنجاح'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                    );
                  }
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
    MerchantProvider provider,
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حجم الصورة كبير جداً (يجب أن يكون أقل من 500KB)'),
            ),
          );
        }
        return;
      }

      const bucketId = 'images';
      final result = await provider.storage.createFile(
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في رفع الصورة: ${e.toString()}')),
        );
      }
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
                            provider,
                          ),
                          child: const Text('من المعرض'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async => _uploadImage(
                            ImageSource.camera,
                            imageController,
                            provider,
                          ),
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
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إضافة المنتج بنجاح')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                    );
                  }
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
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المنتج',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'السعر'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'مطلوب' : null,
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
                                provider,
                              ),
                              child: const Text('من المعرض'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async => _uploadImage(
                                ImageSource.camera,
                                imageController,
                                provider,
                              ),
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
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      items: provider.categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => selectedCategoryId = value),
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
              );
            },
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
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديث المنتج بنجاح')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                    );
                  }
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
        await provider.databases.deleteDocument(
          databaseId: 'mahllnadb',
          collectionId: 'Products',
          documentId: productId,
        );
        provider.products.removeWhere((p) => p.id == productId);
        provider.notifyListeners();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حذف المنتج بنجاح')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
        }
      }
    }
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

                  await provider.databases.updateDocument(
                    databaseId: 'mahllnadb',
                    collectionId: 'ProductCategories',
                    documentId: category.id,
                    data: updatedCategory.toMap(),
                  );

                  final index = provider.categories.indexWhere(
                    (c) => c.id == category.id,
                  );
                  if (index != -1) {
                    provider.categories[index] = updatedCategory;
                    provider.notifyListeners();
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديث التصنيف بنجاح')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                    );
                  }
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
        await provider.databases.deleteDocument(
          databaseId: 'mahllnadb',
          collectionId: 'ProductCategories',
          documentId: categoryId,
        );
        provider.categories.removeWhere((c) => c.id == categoryId);
        provider.notifyListeners();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حذف التصنيف بنجاح')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
        }
      }
    }
  }
}

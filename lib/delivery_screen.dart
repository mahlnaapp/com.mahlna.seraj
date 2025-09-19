import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_provider.dart';
import 'store_screen.dart';
import 'store_model.dart';
import 'store_service.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'settings_screen.dart';
import 'auth_screen.dart';

// ===================== UserInfoScreen =====================
class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  String? userName;
  String? userEmail;
  String? userId;
  bool _isDeleting = false; // <-- المتغير مُعرّف هنا

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      userName = prefs.getString('userName');
      userEmail = prefs.getString('userEmail');
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا يوجد حساب لحذفه')));
      return;
    }

    setState(() => _isDeleting = true);

    try {
      final client = Client()
          .setEndpoint("https://fra.cloud.appwrite.io/v1")
          .setProject("6887ee78000e74d711f1");

      final databases = Databases(client);

      // حذف حساب المستخدم من Appwrite
      await databases.deleteDocument(
        databaseId: "mahllnadb",
        collectionId: "clients",
        documentId: userId,
      );

      // مسح البيانات المحلية
      await prefs.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف الحساب بنجاح')));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل في حذف الحساب: $e')));
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل أنت متأكد من أنك تريد حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _deleteAccount,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );
  }

  void _navigateToAuthScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معلومات المستخدم'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userId == null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'لم تقم بتسجيل الدخول',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'سجل الدخول للوصول إلى جميع الميزات',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // زر تسجيل الدخول
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _navigateToAuthScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // زر إنشاء حساب جديد
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _navigateToAuthScreen,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.orange),
                        ),
                        child: const Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // قسم الدخول كضيف
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'يمكنك الاستمرار كضيف',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'التصفح وإضافة المنتجات إلى السلة',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'معلومات الحساب',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(
                    'الاسم',
                    userName ?? 'غير متوفر',
                    Icons.person,
                  ),
                  _buildInfoCard(
                    'البريد الإلكتروني',
                    userEmail ?? 'غير متوفر',
                    Icons.email,
                  ),
                  _buildInfoCard(
                    'رقم المستخدم',
                    userId ?? 'غير متوفر',
                    Icons.code,
                  ),
                  const SizedBox(height: 30),

                  // زر تسجيل الخروج
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // زر حذف الحساب
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showDeleteConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isDeleting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'حذف الحساب',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== DeliveryScreen =====================
class DeliveryScreen extends StatefulWidget {
  final String deliveryCity;
  final String? zoneId;

  const DeliveryScreen({super.key, required this.deliveryCity, this.zoneId});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isLoadingMore = false; // <-- المتغير المطلوب استخدامه
  double? _userLat;
  double? _userLon;
  List<Store> _stores = [];
  int _currentIndex = 0;
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  bool _hasMoreStores = true;

  final List<String> _categories = [
    'الكل',
    'سوبرماركت',
    'البان واجبان',
    'أفران',
    'حلويات وكرزات',
    'مواد غذائية',
    'مطاعم',
    'عطارية',
    'مرطبات',
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      _buildHomeContent(), // وضعت الدالة هنا لتجنب الحاجة لتغيير currentIndex = 0
      const CartScreen(),
      const OrdersScreen(),
      const SettingsScreen(),
      const UserInfoScreen(),
    ];

    _getUserLocation();
    _loadInitialStores();
  }

  // تم نقل دالة بناء المحتوى الرئيسي إلى initState لتجنب استدعاء BuildContext بشكل مباشر
  Widget _buildHomeContent() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoriesBar(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                )
              : _filteredStores.isEmpty
              ? _buildEmptyState()
              : _buildStoresList(),
        ),
      ],
    );
  }

  Future<void> _getUserLocation() async {
    try {
      setState(() {
        _userLat = 36.3350;
        _userLon = 43.1150;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل في الحصول على الموقع: $e')));
    }
  }

  Future<void> _loadInitialStores() async {
    try {
      final storeService = Provider.of<StoreService>(context, listen: false);
      final stores = await storeService.getStores(
        limit: _itemsPerPage,
        offset: 0,
        userLat: _userLat,
        userLon: _userLon,
        zoneId: widget.zoneId,
      );

      setState(() {
        _stores = stores;
        _isLoading = false;
        _currentPage = 1;
        _hasMoreStores = stores.length == _itemsPerPage;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل في تحميل المتاجر: $e')));
    }
  }

  Future<void> _loadMoreStores() async {
    if (_isLoadingMore || !_hasMoreStores) return;

    setState(() => _isLoadingMore = true);

    try {
      final storeService = Provider.of<StoreService>(context, listen: false);
      final newStores = await storeService.getStores(
        limit: _itemsPerPage,
        offset: _currentPage * _itemsPerPage,
        userLat: _userLat,
        userLon: _userLon,
        zoneId: widget.zoneId,
      );

      setState(() {
        if (newStores.isEmpty) {
          _hasMoreStores = false;
        } else {
          _stores.addAll(newStores);
          _currentPage++;
          _hasMoreStores = newStores.length == _itemsPerPage;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل المزيد من المتاجر: $e')),
      );
    } finally {
      // تم تصحيح الخطأ هنا: تم استبدال _isDeleting بـ _isLoadingMore
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Store> get _filteredStores {
    final searchText = _searchController.text.toLowerCase();
    return _stores.where((store) {
      final categoryMatch =
          _selectedCategoryIndex == 0 ||
          (store.category == _categories[_selectedCategoryIndex]);
      final searchMatch =
          searchText.isEmpty ||
          store.name.toLowerCase().contains(searchText) ||
          store.category.toLowerCase().contains(searchText);
      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('توصيل إلى ${widget.deliveryCity}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => setState(() => _currentIndex = 2),
          ),
          _buildCartIconWithBadge(context),
        ],
      ),
      body: _pages[_currentIndex], // استخدام القائمة المُهيأة
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() {
          _currentIndex = index;
          // إعادة بناء محتوى الصفحة الرئيسية إذا تم النقر عليها
          if (_currentIndex == 0) {
            _pages[0] = _buildHomeContent();
          }
        }),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.orange,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'السلة',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'طلباتي'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'مستخدم'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث عن متجر أو منتج...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildCategoriesBar() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) => _buildCategoryItem(index),
      ),
    );
  }

  Widget _buildCategoryItem(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(_categories[index]),
        selected: _selectedCategoryIndex == index,
        onSelected: (selected) =>
            setState(() => _selectedCategoryIndex = index),
        selectedColor: Colors.orange[700],
        labelStyle: TextStyle(
          color: _selectedCategoryIndex == index ? Colors.white : Colors.black,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildStoresList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification.metrics.pixels ==
            scrollNotification.metrics.maxScrollExtent) {
          _loadMoreStores();
        }
        return true;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _filteredStores.length + (_hasMoreStores ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _filteredStores.length)
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            );
          return _buildStoreItem(_filteredStores[index]);
        },
      ),
    );
  }

  Widget _buildStoreItem(Store store) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: store.isOpen
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoreScreen(
                    storeName: store.name,
                    storeId: store.id,
                    isStoreOpen: store.isOpen,
                  ),
                ),
              )
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('المتجر مغلق حالياً')),
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: store.image.isEmpty
                    ? Icon(Icons.store, size: 40, color: Colors.grey[600])
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          store.image,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.store,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          store.isOpen ? Icons.check_circle : Icons.cancel,
                          color: store.isOpen ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ],
                    ),
                    Text(
                      store.category,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        Expanded(
                          child: Text(
                            store.address ?? "الموقع غير متوفر",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: store.isOpen
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            store.isOpen ? 'مفتوح الآن' : 'مغلق',
                            style: TextStyle(
                              color: store.isOpen ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
          Icon(
            Icons.store_mall_directory_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد متاجر متاحة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategoryIndex == 0
                ? 'لا توجد متاجر في منطقتك'
                : 'لا توجد متاجر في هذا التصنيف',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCartIconWithBadge(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) => Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => setState(() => _currentIndex = 1),
          ),
          if (cart.itemCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text(
                  cart.itemCount.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

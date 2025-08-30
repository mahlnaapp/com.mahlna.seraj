import 'package:flutter/material.dart';
import 'package:appfotajer/main.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'store_screen.dart';
import 'dart:math';
import 'store_model.dart';
import 'store_service.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';

class DeliveryScreen extends StatefulWidget {
  final String deliveryCity;

  const DeliveryScreen({super.key, required this.deliveryCity});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isLoadingMore = false;
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
    'أفران',
    'مواد غذائية',
    'مطاعم',
  ];

  List<Widget> get _pages => [
    const DeliveryScreen(deliveryCity: "الموصل"),
    const CartScreen(),
    const OrdersScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadInitialStores();
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
            onPressed: () => Navigator.pushNamed(context, '/orders'),
          ),
          _buildCartIconWithBadge(context),
        ],
      ),
      body: _currentIndex == 0 ? _buildHomeContent() : _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.orange,
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
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoriesBar(),
        Expanded(
          child: _isLoading
              ? _buildLoadingState()
              : _filteredStores.isEmpty
              ? _buildEmptyState()
              : _buildStoresList(),
        ),
      ],
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
        selectedColor: Colors.orange,
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
          if (index >= _filteredStores.length) {
            return _buildLoadingMoreIndicator();
          }
          return _buildStoreItem(_filteredStores[index]);
        },
      ),
    );
  }

  Widget _buildStoreItem(Store store) {
    final distance = store.distance ?? 0.0;

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
                        Text(' ${distance.toStringAsFixed(1)} كم'),
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

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: Colors.orange));
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator(color: Colors.orange)),
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

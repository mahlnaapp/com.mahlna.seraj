import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'cart_provider.dart';
import 'product_category_service.dart';
import 'store_model.dart';
import 'appwrite_service.dart';
import 'product_category_model.dart';
import 'product_service.dart';
import 'order_service.dart';
import 'order_item_model.dart';

class StoreScreen extends StatefulWidget {
  final String storeName;
  final String storeId;
  final bool isStoreOpen;

  const StoreScreen({
    super.key,
    required this.storeName,
    required this.storeId,
    this.isStoreOpen = true,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late ProductCategoryService _categoryService;
  late ProductService _productService;
  List<ProductCategory> _categories = [];
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  bool _hasMoreProducts = true;

  @override
  void initState() {
    super.initState();
    _categoryService = ProductCategoryService(AppwriteService.databases);
    _productService = ProductService(AppwriteService.databases);
    _loadInitialData();
  }

  Future<void> _loadProducts({String? categoryId, bool reset = false}) async {
    if (reset) {
      _products.clear();
      _currentPage = 0;
      _hasMoreProducts = true;
      setState(() => _isLoading = true);
    } else {
      if (_isLoadingMore || !_hasMoreProducts) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final newProducts = await _productService.getProducts(
        storeId: widget.storeId,
        limit: _itemsPerPage,
        offset: _currentPage * _itemsPerPage,
        categoryId: categoryId,
      );

      setState(() {
        if (reset) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
          _currentPage++;
        }
        _hasMoreProducts = newProducts.length == _itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل في تحميل المنتجات: $e')));
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final categories = await _categoryService.getCategoriesByStore(
        widget.storeId,
      );

      // جلب المنتجات الأولية
      final products = await _productService.getProducts(
        storeId: widget.storeId,
        limit: _itemsPerPage,
      );

      setState(() {
        _categories = categories;
        _products = products;
        _isLoading = false;
        _hasMoreProducts = products.length == _itemsPerPage;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل في تحميل البيانات: $e')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    final searchText = _searchController.text.toLowerCase();

    // 💡 لا توجد حاجة هنا لتصفية المنتجات حسب التصنيف، لأنها تأتي مصفاة من الخادم
    if (searchText.isEmpty) {
      return _products;
    }

    return _products.where((product) {
      return product.name.toLowerCase().contains(searchText) ||
          product.description.toLowerCase().contains(searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isStoreOpen) {
      return _buildStoreClosed();
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredProducts.isEmpty
                ? _buildEmptyState()
                : _buildProductsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreClosed() {
    return Scaffold(
      appBar: AppBar(title: Text(widget.storeName), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'المتجر مغلق حالياً',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'يرجى المحاولة في وقت لاحق',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(widget.storeName, style: TextStyle(color: Colors.black)),
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black),
      actions: [
        IconButton(
          icon: Icon(Icons.list_alt),
          onPressed: () => Navigator.pushNamed(context, '/orders'),
        ),
        _buildCartIconWithBadge(context),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(Icons.close, color: Colors.grey),
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

  Widget _buildCategoryBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) => _buildCategoryItem(index),
      ),
    );
  }

  Widget _buildCategoryItem(int index) {
    final isAllCategory = index == 0;
    final categoryName = isAllCategory ? 'الكل' : _categories[index - 1].name;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(categoryName),
        selected: _selectedCategoryIndex == index,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategoryIndex = index;
            });
            final categoryId = isAllCategory ? null : _categories[index - 1].id;
            // 🚀 استدعاء الدالة الجديدة مع إشارة reset
            _loadProducts(categoryId: categoryId, reset: true);
          }
        },
        selectedColor: Colors.orange,
        labelStyle: TextStyle(
          color: _selectedCategoryIndex == index ? Colors.white : Colors.black,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildProductsList() {
    final productsToShow = _filteredProducts;
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification.metrics.pixels >=
                scrollNotification.metrics.maxScrollExtent - 200 &&
            !_isLoadingMore) {
          final categoryId = _selectedCategoryIndex == 0
              ? null
              : _categories[_selectedCategoryIndex - 1].id;
          _loadProducts(categoryId: categoryId);
        }
        return false;
      },
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 16),
        itemCount: productsToShow.length + (_hasMoreProducts ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= productsToShow.length) {
            return _buildLoadingMoreIndicator();
          }
          return _buildProductItem(productsToShow[index]);
        },
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    final isAvailable = product.isAvailable;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: product.image.isEmpty
                    ? Icon(Icons.fastfood, size: 40, color: Colors.grey[600])
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          product.image,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.fastfood,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      product.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    if (!isAvailable)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'غير متوفر حالياً',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          NumberFormat.currency(
                            symbol: 'د.ع',
                            decimalDigits: 0,
                          ).format(product.price),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 16,
                          ),
                        ),
                        if (product.hasOffer)
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'عرض',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle,
                            color: isAvailable ? Colors.orange : Colors.grey,
                            size: 30,
                          ),
                          onPressed: isAvailable
                              ? () {
                                  Provider.of<CartProvider>(
                                    context,
                                    listen: false,
                                  ).addItemWithNotification(
                                    context,
                                    productId: product.id,
                                    name: product.name,
                                    price: product.price,
                                    image: product.image,
                                    storeId: widget.storeId,
                                    storeName: widget.storeName,
                                  );
                                }
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'هذا المنتج غير متوفر حالياً',
                                      ),
                                    ),
                                  );
                                },
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
    return Center(child: CircularProgressIndicator(color: Colors.orange));
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator(color: Colors.orange)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood_outlined, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'لا توجد منتجات متاحة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            _selectedCategoryIndex == 0
                ? 'جاري تحميل المنتجات...'
                : 'لا توجد منتجات في هذا التصنيف',
            style: TextStyle(color: Colors.grey),
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
            icon: Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
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
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Store {
  final String id;
  final String name;
  final String category;
  final String image;
  final bool isOpen;
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;
  double? distance; // أضف هذا الحقل

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
    this.distance, // أضفه هنا أيضاً
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
    };
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final bool isAvailable;
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
}

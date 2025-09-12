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

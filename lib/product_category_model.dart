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
    this.order = 0,
    this.isActive = true,
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

  @override
  String toString() =>
      'ProductCategory(id: $id, name: $name, storeId: $storeId)';
}

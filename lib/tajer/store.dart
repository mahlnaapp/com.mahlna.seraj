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

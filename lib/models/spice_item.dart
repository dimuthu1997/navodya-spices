class SpiceItem {
  final String id;
  final String name;
  final String sinhalaName;
  final String category; // e.g. 'Pure Spices', 'Blended Powders', 'Whole Spices', 'Special Kits'
  final double price; // price per unit weight
  final String unit; // e.g. '100g', '250g', '500g', '1kg'
  final int stock;
  final String imageUrl;
  final String description;
  final double rating;
  final bool isPopular;
  final List<String> ingredients;

  SpiceItem({
    required this.id,
    required this.name,
    required this.sinhalaName,
    required this.category,
    required this.price,
    required this.unit,
    required this.stock,
    required this.imageUrl,
    required this.description,
    this.rating = 4.8,
    this.isPopular = false,
    this.ingredients = const [],
  });

  // Calculate dynamic price based on weight variant (50g, 100g, 250g, 500g, 1Kg)
  double getPriceForWeight(String targetUnit) {
    switch (targetUnit) {
      case '50g':
        return (price * 0.5);
      case '100g':
        return price;
      case '250g':
        return (price * 2.5);
      case '500g':
        return (price * 5.0);
      case '1Kg':
      case '1kg':
        return (price * 10.0);
      default:
        return price;
    }
  }

  // Unique QR Payload for scanning
  String get qrPayload => 'NAV_SPICE:$id:$price:$unit';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sinhalaName': sinhalaName,
      'category': category,
      'price': price,
      'unit': unit,
      'stock': stock,
      'imageUrl': imageUrl,
      'description': description,
      'rating': rating,
      'isPopular': isPopular,
      'ingredients': ingredients,
    };
  }

  factory SpiceItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    return SpiceItem(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      sinhalaName: map['sinhalaName'] ?? '',
      category: map['category'] ?? 'Pure Spices',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '100g',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
      isPopular: map['isPopular'] ?? false,
      ingredients: (map['ingredients'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

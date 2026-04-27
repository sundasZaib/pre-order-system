class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    required this.category,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
    };
  }

  factory MenuItem.fromMap(String id, Map<String, dynamic> map) {
    return MenuItem(
      id: id,
      name: (map['name'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      category: (map['category'] as String?) ?? '',
      imageUrl: (map['imageUrl'] as String?) ?? '',
    );
  }
}

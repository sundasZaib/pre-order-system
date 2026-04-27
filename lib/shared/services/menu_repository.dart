import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pre_order_system/shared/models/menu_item.dart';

class MenuRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static List<String> categories = [
    'Drinks',
    'Fast Food',
    'Meals',
    'Desserts',
  ];

  static CollectionReference<Map<String, dynamic>> get _menuCollection =>
      _firestore.collection('menu_items');

  static final List<MenuItem> menu = [
    // Drinks
    MenuItem(
      id: '1',
      name: 'Doodh Patti Chai',
      description: 'Traditional milk tea with rich flavor.',
      price: 120,
      category: 'Drinks',
      imageUrl: 'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '2',
      name: 'Mango Lassi',
      description: 'Sweet chilled yogurt mango drink.',
      price: 240,
      category: 'Drinks',
      imageUrl: 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '3',
      name: 'Fresh Orange Juice',
      description: 'Freshly squeezed orange juice.',
      price: 180,
      category: 'Drinks',
      imageUrl: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '4',
      name: 'Cold Coffee',
      description: 'Creamy chilled coffee drink.',
      price: 280,
      category: 'Drinks',
      imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '5',
      name: 'Lemonade',
      description: 'Refreshing lemon and mint cooler.',
      price: 150,
      category: 'Drinks',
      imageUrl: 'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=400&h=260&fit=crop',
    ),

    // Fast Food
    MenuItem(
      id: '6',
      name: 'Bun Kebab',
      description: 'Classic local bun kebab.',
      price: 180,
      category: 'Fast Food',
      imageUrl: 'https://images.unsplash.com/photo-1603360946369-dc9bb6258143?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '7',
      name: 'Chicken Burger',
      description: 'Juicy chicken fillet burger.',
      price: 350,
      category: 'Fast Food',
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '8',
      name: 'Crispy Fries',
      description: 'Golden crispy french fries.',
      price: 200,
      category: 'Fast Food',
      imageUrl: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '9',
      name: 'Chicken Shawarma',
      description: 'Spiced chicken wrap with sauce.',
      price: 320,
      category: 'Fast Food',
      imageUrl: 'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '10',
      name: 'Pizza Slice',
      description: 'Cheesy pizza slice.',
      price: 280,
      category: 'Fast Food',
      imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '11',
      name: 'Chicken Nuggets',
      description: 'Crunchy chicken nuggets.',
      price: 350,
      category: 'Fast Food',
      imageUrl: 'https://images.unsplash.com/photo-1562967914-608f82629710?w=400&h=260&fit=crop',
    ),

    // Meals
    MenuItem(
      id: '12',
      name: 'Chicken Biryani',
      description: 'Aromatic chicken biryani.',
      price: 420,
      category: 'Meals',
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '13',
      name: 'Beef Nihari',
      description: 'Slow-cooked spicy beef nihari.',
      price: 540,
      category: 'Meals',
      imageUrl: 'https://images.unsplash.com/photo-1545247181-516773cae754?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '14',
      name: 'Lahori Chargha',
      description: 'Crispy Lahori-style chicken.',
      price: 690,
      category: 'Meals',
      imageUrl: 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '15',
      name: 'Chana Kulcha',
      description: 'Spiced chickpeas with soft kulcha.',
      price: 260,
      category: 'Meals',
      imageUrl: 'https://images.unsplash.com/photo-1626132647523-66f5bf380027?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '16',
      name: 'Karahi Chicken',
      description: 'Traditional karahi chicken curry.',
      price: 580,
      category: 'Meals',
      imageUrl: 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '17',
      name: 'Dal Chawal',
      description: 'Comfort lentils and rice combo.',
      price: 220,
      category: 'Meals',
      imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400&h=260&fit=crop',
    ),

    // Desserts
    MenuItem(
      id: '18',
      name: 'Gulab Jamun',
      description: 'Soft syrupy milk dumplings.',
      price: 180,
      category: 'Desserts',
      imageUrl: 'https://images.unsplash.com/photo-1666190077229-fdf0247b00c8?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '19',
      name: 'Kheer',
      description: 'Creamy rice pudding dessert.',
      price: 200,
      category: 'Desserts',
      imageUrl: 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '20',
      name: 'Chocolate Brownie',
      description: 'Warm chocolate fudge brownie.',
      price: 250,
      category: 'Desserts',
      imageUrl: 'https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '21',
      name: 'Ice Cream',
      description: 'Creamy scoops of ice cream.',
      price: 180,
      category: 'Desserts',
      imageUrl: 'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '22',
      name: 'Fruit Custard',
      description: 'Fresh fruit with vanilla custard.',
      price: 220,
      category: 'Desserts',
      imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400&h=260&fit=crop',
    ),
  ];

  static Future<void> ensureSeedData() async {
    final existing = await _menuCollection.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final item in menu) {
      final docRef = _menuCollection.doc();
      batch.set(docRef, {
        ...item.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  static Stream<List<MenuItem>> streamMenuItems() {
    return _menuCollection.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => MenuItem.fromMap(doc.id, doc.data()))
          .toList();

      items.sort((a, b) {
        final byCategory = a.category.toLowerCase().compareTo(b.category.toLowerCase());
        if (byCategory != 0) {
          return byCategory;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return items;
    });
  }

  static List<MenuItem> getItemsByCategory(List<MenuItem> items, String category) {
    return items.where((item) => item.category == category).toList();
  }

  static Future<void> addMenuItem({
    required String name,
    required String description,
    required double price,
    required String category,
    required String imageUrl,
  }) async {
    await _menuCollection.add({
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'category': category,
      'imageUrl': imageUrl.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateMenuItem({
    required String id,
    required String name,
    required String description,
    required double price,
    required String category,
    required String imageUrl,
  }) async {
    await _menuCollection.doc(id).update({
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'category': category,
      'imageUrl': imageUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteMenuItem(String id) async {
    await _menuCollection.doc(id).delete();
  }

  // CRUD operations for categories
  static void addCategory(String category) {
    if (!categories.contains(category)) {
      categories.add(category);
    }
  }

  static void updateCategory(String oldCategory, String newCategory) {
    final index = categories.indexOf(oldCategory);
    if (index != -1) {
      categories[index] = newCategory;
      // Update all menu items with this category
      for (int i = 0; i < menu.length; i++) {
        if (menu[i].category == oldCategory) {
          menu[i] = MenuItem(
            id: menu[i].id,
            name: menu[i].name,
            price: menu[i].price,
            category: newCategory,
            imageUrl: menu[i].imageUrl,
          );
        }
      }
    }
  }

  static void deleteCategory(String category) {
    categories.remove(category);
    // Remove all menu items with this category
    menu.removeWhere((item) => item.category == category);
  }
}


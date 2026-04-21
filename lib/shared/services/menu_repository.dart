import 'package:pre_order_system/shared/models/menu_item.dart';

class MenuRepository {
  static List<String> categories = [
    'Drinks',
    'Fast Food',
    'Meals',
    'Desserts',
  ];

  static List<MenuItem> getItemsByCategory(String category) {
    return menu.where((item) => item.category == category).toList();
  }

  static List<MenuItem> menu = [
    // Drinks
    MenuItem(
      id: '1',
      name: 'Doodh Patti Chai',
      price: 120,
      category: 'Drinks',
      imageUrl: 'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '2',
      name: 'Mango Lassi',
      price: 240,
      category: 'Drinks',
      imageUrl: 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '3',
      name: 'Fresh Orange Juice',
      price: 180,
      category: 'Drinks',
      imageUrl: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '4',
      name: 'Cold Coffee',
      price: 280,
      category: 'Drinks',
      imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '5',
      name: 'Lemonade',
      price: 150,
      category: 'Drinks',
      imageUrl: 'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=400&h=260&fit=crop',
    ),

    // Fast Food
    MenuItem(
      id: '6',
      name: 'Bun Kebab',
      price: 180,
      category: 'Fast Food',
      imageUrl: 'https://images.unsplash.com/photo-1603360946369-dc9bb6258143?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '7',
      name: 'Chicken Burger',
      price: 350,
      category: 'Fast Food',
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '8',
      name: 'Crispy Fries',
      price: 200,
      category: 'Fast Food',
      imageUrl: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '9',
      name: 'Chicken Shawarma',
      price: 320,
      category: 'Fast Food',
      imageUrl: 'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '10',
      name: 'Pizza Slice',
      price: 280,
      category: 'Fast Food',
      imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '11',
      name: 'Chicken Nuggets',
      price: 350,
      category: 'Fast Food',
      imageUrl: 'https://images.unsplash.com/photo-1562967914-608f82629710?w=400&h=260&fit=crop',
    ),

    // Meals
    MenuItem(
      id: '12',
      name: 'Chicken Biryani',
      price: 420,
      category: 'Meals',
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '13',
      name: 'Beef Nihari',
      price: 540,
      category: 'Meals',
      imageUrl: 'https://images.unsplash.com/photo-1545247181-516773cae754?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '14',
      name: 'Lahori Chargha',
      price: 690,
      category: 'Meals',
      imageUrl: 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '15',
      name: 'Chana Kulcha',
      price: 260,
      category: 'Meals',
      imageUrl: 'https://images.unsplash.com/photo-1626132647523-66f5bf380027?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '16',
      name: 'Karahi Chicken',
      price: 580,
      category: 'Meals',
      imageUrl: 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '17',
      name: 'Dal Chawal',
      price: 220,
      category: 'Meals',
      imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400&h=260&fit=crop',
    ),

    // Desserts
    MenuItem(
      id: '18',
      name: 'Gulab Jamun',
      price: 180,
      category: 'Desserts',
      imageUrl: 'https://images.unsplash.com/photo-1666190077229-fdf0247b00c8?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '19',
      name: 'Kheer',
      price: 200,
      category: 'Desserts',
      imageUrl: 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '20',
      name: 'Chocolate Brownie',
      price: 250,
      category: 'Desserts',
      imageUrl: 'https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '21',
      name: 'Ice Cream',
      price: 180,
      category: 'Desserts',
      imageUrl: 'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=400&h=260&fit=crop',
    ),
    MenuItem(
      id: '22',
      name: 'Fruit Custard',
      price: 220,
      category: 'Desserts',
      imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400&h=260&fit=crop',
    ),
  ];

  // CRUD operations for menu items
  static void addMenuItem(String name, double price, String category, String image) {
    final newId = (menu.length + 1).toString();
    menu.add(MenuItem(
      id: newId,
      name: name,
      price: price,
      category: category,
      imageUrl: image,
    ));
  }

  static void updateMenuItem(String id, String name, double price, String category, String image) {
    final index = menu.indexWhere((item) => item.id == id);
    if (index != -1) {
      menu[index] = MenuItem(
        id: id,
        name: name,
        price: price,
        category: category,
        imageUrl: image,
      );
    }
  }

  static void deleteMenuItem(String id) {
    menu.removeWhere((item) => item.id == id);
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


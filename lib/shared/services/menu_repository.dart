import 'package:pre_order_system/shared/models/menu_item.dart';

class MenuRepository {
  static const List<MenuItem> menu = [
    MenuItem(
      id: '1',
      name: 'Doodh Patti Chai',
      price: 120,
      category: 'Beverages',
      imageUrl: 'https://picsum.photos/id/292/400/260',
    ),
    MenuItem(
      id: '2',
      name: 'Bun Kebab',
      price: 180,
      category: 'Snacks',
      imageUrl: 'https://picsum.photos/id/431/400/260',
    ),
    MenuItem(
      id: '3',
      name: 'Lahori Chana Kulcha',
      price: 260,
      category: 'Breakfast',
      imageUrl: 'https://picsum.photos/id/1080/400/260',
    ),
    MenuItem(
      id: '4',
      name: 'Chicken Biryani',
      price: 420,
      category: 'Lunch',
      imageUrl: 'https://picsum.photos/id/225/400/260',
    ),
    MenuItem(
      id: '5',
      name: 'Lahori Chargha',
      price: 690,
      category: 'BBQ',
      imageUrl: 'https://picsum.photos/id/488/400/260',
    ),
    MenuItem(
      id: '6',
      name: 'Beef Nihari',
      price: 540,
      category: 'Lunch',
      imageUrl: 'https://picsum.photos/id/312/400/260',
    ),
    MenuItem(
      id: '7',
      name: 'Mango Lassi',
      price: 240,
      category: 'Beverages',
      imageUrl: 'https://picsum.photos/id/102/400/260',
    ),
  ];
}

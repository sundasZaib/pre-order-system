import 'package:pre_order_system/shared/models/menu_item.dart';

enum OrderStatus {
  pending,
  preparing,
  ready,
  completed,
}

OrderStatus orderStatusFromString(String value) {
  switch (value) {
    case 'preparing':
      return OrderStatus.preparing;
    case 'ready':
      return OrderStatus.ready;
    case 'completed':
      return OrderStatus.completed;
    case 'pending':
    default:
      return OrderStatus.pending;
  }
}

class OrderItem {
  const OrderItem({
    required this.menuItem,
    required this.quantity,
  });

  final MenuItem menuItem;
  final int quantity;

  double get total => menuItem.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'menuItem': {
        'id': menuItem.id,
        'name': menuItem.name,
        'price': menuItem.price,
        'category': menuItem.category,
        'imageUrl': menuItem.imageUrl,
      },
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    final menuMap = (map['menuItem'] as Map<String, dynamic>? ?? {});
    return OrderItem(
      menuItem: MenuItem(
        id: (menuMap['id'] as String?) ?? '',
        name: (menuMap['name'] as String?) ?? '',
        price: (menuMap['price'] as num?)?.toDouble() ?? 0,
        category: (menuMap['category'] as String?) ?? '',
        imageUrl: (menuMap['imageUrl'] as String?) ?? '',
      ),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

class Order {
  Order({
    required this.id,
    required this.token,
    required this.userId,
    required this.userName,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.status = OrderStatus.pending,
    this.estimatedMinutes = 15,
  });

  final String id;
  final String token;
  final String userId;
  final String userName;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime createdAt;
  OrderStatus status;
  int estimatedMinutes;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'userId': userId,
      'userName': userName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'createdAt': createdAt,
      'status': status.name,
      'estimatedMinutes': estimatedMinutes,
    };
  }
}

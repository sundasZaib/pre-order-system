import 'package:pre_order_system/shared/models/menu_item.dart';

enum OrderStatus {
  pending,
  preparing,
  ready,
  completed,
}

class OrderItem {
  const OrderItem({
    required this.menuItem,
    required this.quantity,
  });

  final MenuItem menuItem;
  final int quantity;

  double get total => menuItem.price * quantity;
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
}

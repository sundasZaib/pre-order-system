import 'dart:async';
import 'package:pre_order_system/shared/models/menu_item.dart';
import 'package:pre_order_system/shared/models/order.dart';
import 'package:pre_order_system/features/orders/token_service.dart';

class OrderService {
  OrderService._();

  static final OrderService instance = OrderService._();

  final List<Order> _orders = [];
  String? _currentServingToken;
  int _orderIdCounter = 0;

  final _ordersController = StreamController<List<Order>>.broadcast();
  final _currentTokenController = StreamController<String?>.broadcast();

  Stream<List<Order>> get ordersStream => _ordersController.stream;
  Stream<String?> get currentTokenStream => _currentTokenController.stream;

  List<Order> get allOrders => List.unmodifiable(_orders);
  
  List<Order> get activeOrders => _orders
      .where((o) => o.status != OrderStatus.completed)
      .toList();

  List<Order> get pendingOrders => _orders
      .where((o) => o.status == OrderStatus.pending)
      .toList();

  List<Order> get preparingOrders => _orders
      .where((o) => o.status == OrderStatus.preparing)
      .toList();

  List<Order> get readyOrders => _orders
      .where((o) => o.status == OrderStatus.ready)
      .toList();

  List<Order> get completedOrders => _orders
      .where((o) => o.status == OrderStatus.completed)
      .toList();

  String? get currentServingToken => _currentServingToken;

  int get currentTokenNumber => _orders.isNotEmpty ? int.tryParse(_orders.last.token) ?? 1000 : 1000;

  int get queuePosition {
    final pending = pendingOrders.length;
    final preparing = preparingOrders.length;
    return pending + preparing;
  }

  Order placeOrder({
    required String userId,
    required String userName,
    required Map<String, int> quantities,
    required List<MenuItem> menuItems,
  }) {
    _orderIdCounter++;
    final token = TokenService.instance.generateDailyToken();
    
    final orderItems = <OrderItem>[];
    double total = 0;
    
    for (final item in menuItems) {
      final qty = quantities[item.id] ?? 0;
      if (qty > 0) {
        orderItems.add(OrderItem(menuItem: item, quantity: qty));
        total += item.price * qty;
      }
    }

    final order = Order(
      id: _orderIdCounter.toString(),
      token: token,
      userId: userId,
      userName: userName,
      items: orderItems,
      totalAmount: total,
      createdAt: DateTime.now(),
      estimatedMinutes: 10 + (orderItems.length * 3),
    );

    _orders.add(order);
    _notifyListeners();
    
    return order;
  }

  Order? getOrderByToken(String token) {
    try {
      return _orders.firstWhere((o) => o.token == token);
    } catch (_) {
      return null;
    }
  }

  List<Order> getOrdersByUserId(String oderId) {
    return _orders.where((o) => o.userId == oderId).toList();
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex != -1) {
      _orders[orderIndex].status = newStatus;
      
      if (newStatus == OrderStatus.ready) {
        _currentServingToken = _orders[orderIndex].token;
        _currentTokenController.add(_currentServingToken);
      }
      
      _notifyListeners();
    }
  }

  void callNextToken() {
    // Find the first pending order and start preparing
    final pendingList = pendingOrders;
    if (pendingList.isNotEmpty) {
      updateOrderStatus(pendingList.first.id, OrderStatus.preparing);
    }
  }

  void markAsReady(String orderId) {
    updateOrderStatus(orderId, OrderStatus.ready);
  }

  void markAsCompleted(String orderId) {
    updateOrderStatus(orderId, OrderStatus.completed);
  }

  int getEstimatedWaitTime(String token) {
    final order = getOrderByToken(token);
    if (order == null) return 0;
    
    int position = 0;
    for (final o in _orders) {
      if (o.token == token) break;
      if (o.status == OrderStatus.pending || o.status == OrderStatus.preparing) {
        position++;
      }
    }
    
    return position * 5 + order.estimatedMinutes;
  }

  void _notifyListeners() {
    _ordersController.add(List.unmodifiable(_orders));
  }

  void dispose() {
    _ordersController.close();
    _currentTokenController.close();
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_database/firebase_database.dart';
import 'package:pre_order_system/features/orders/token_service.dart';
import 'package:pre_order_system/shared/models/menu_item.dart';
import 'package:pre_order_system/shared/models/order.dart';

class OrderService {
  OrderService._() {
    _servingTokenSubscription = _database.child(_servingTokenPath).onValue.listen((event) {
      final value = event.snapshot.value;
      _currentServingToken = value?.toString();
      _currentTokenController.add(_currentServingToken);
    });
  }

  static final OrderService instance = OrderService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static const String _servingTokenPath = 'canteen/currentServingToken';

  final List<Order> _orders = [];
  String? _currentServingToken;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSubscription;
  StreamSubscription<DatabaseEvent>? _servingTokenSubscription;
  bool _isInitialized = false;

  final _ordersController = StreamController<List<Order>>.broadcast();
  final _currentTokenController = StreamController<String?>.broadcast();

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  Stream<List<Order>> get ordersStream {
    _ensureInitialized();
    return _ordersController.stream;
  }

  Stream<String?> get currentTokenStream {
    _ensureInitialized();
    return _currentTokenController.stream;
  }

  List<Order> get allOrders {
    _ensureInitialized();
    return List.unmodifiable(_orders);
  }

  List<Order> get activeOrders {
    _ensureInitialized();
    return _orders.where((o) => o.status != OrderStatus.completed).toList();
  }

  List<Order> get pendingOrders {
    _ensureInitialized();
    return _orders.where((o) => o.status == OrderStatus.pending).toList();
  }

  List<Order> get preparingOrders {
    _ensureInitialized();
    return _orders.where((o) => o.status == OrderStatus.preparing).toList();
  }

  List<Order> get readyOrders {
    _ensureInitialized();
    return _orders.where((o) => o.status == OrderStatus.ready).toList();
  }

  List<Order> get completedOrders {
    _ensureInitialized();
    return _orders.where((o) => o.status == OrderStatus.completed).toList();
  }

  String? get currentServingToken => _currentServingToken;

  int get currentTokenNumber =>
      _orders.isNotEmpty ? int.tryParse(_orders.last.token) ?? 1000 : 1000;

  int get queuePosition {
    final pending = pendingOrders.length;
    final preparing = preparingOrders.length;
    return pending + preparing;
  }

  void _ensureInitialized() {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
    _ordersSubscription = _ordersCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      _orders
        ..clear()
        ..addAll(snapshot.docs.map(_mapDocToOrder));

      _updateCurrentServingToken();
      _notifyListeners();
    });
  }

  Order _mapDocToOrder(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawItems = (data['items'] as List<dynamic>? ?? const []);

    final items = rawItems
        .map((item) => OrderItem.fromMap((item as Map).cast<String, dynamic>()))
        .toList();

    final createdAtField = data['createdAt'];
    final createdAt = createdAtField is Timestamp ? createdAtField.toDate() : DateTime.now();

    return Order(
      id: doc.id,
      token: (data['token'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      userName: (data['userName'] as String?) ?? 'User',
      items: items,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      createdAt: createdAt,
      status: orderStatusFromString((data['status'] as String?) ?? 'pending'),
      estimatedMinutes: (data['estimatedMinutes'] as num?)?.toInt() ?? 15,
    );
  }

  void _updateCurrentServingToken() {
    String? readyToken;
    for (final order in _orders.reversed) {
      if (order.status == OrderStatus.ready) {
        readyToken = order.token;
        break;
      }
    }

    if (readyToken != _currentServingToken) {
      _currentServingToken = readyToken;
      _currentTokenController.add(_currentServingToken);
    }
  }

  Order placeOrder({
    required String userId,
    required String userName,
    required Map<String, int> quantities,
    required List<MenuItem> menuItems,
  }) {
    _ensureInitialized();
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
      id: '',
      token: token,
      userId: userId,
      userName: userName,
      items: orderItems,
      totalAmount: total,
      createdAt: DateTime.now(),
      estimatedMinutes: 10 + (orderItems.length * 3),
    );

    unawaited(_ordersCollection.add(order.toMap()));
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
    _ensureInitialized();

    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) {
      return;
    }

    _orders[orderIndex].status = newStatus;

    if (newStatus == OrderStatus.ready) {
      _currentServingToken = _orders[orderIndex].token;
      _currentTokenController.add(_currentServingToken);
      unawaited(_database.child(_servingTokenPath).set(_currentServingToken));
    }

    _notifyListeners();
    unawaited(_ordersCollection.doc(orderId).update({'status': newStatus.name}));
  }

  void callNextToken() {
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
    _ensureInitialized();
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
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _servingTokenSubscription?.cancel();
    _servingTokenSubscription = null;
    _ordersController.close();
    _currentTokenController.close();
    _isInitialized = false;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pre_order_system/app/routes.dart';
import 'package:pre_order_system/shared/models/menu_item.dart';
import 'package:pre_order_system/shared/models/order.dart';
import 'package:pre_order_system/shared/services/menu_repository.dart';
import 'package:pre_order_system/shared/services/mock_auth_service.dart';
import 'package:pre_order_system/shared/services/order_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<MenuItem> _menu = List<MenuItem>.from(MenuRepository.menu);
  List<String> _menuCategories = List<String>.from(MenuRepository.categories);
  final Map<String, int> _selectedQuantities = {};
  int _selectedTabIndex = 0;
  int _selectedCategoryIndex = 0;
  bool _orderAlerts = true;
  bool _emailReceipts = true;

  late TabController _categoryTabController;
  StreamSubscription<List<MenuItem>>? _menuSubscription;

  @override
  void initState() {
    super.initState();
    _categoryTabController = TabController(
      length: _menuCategories.length,
      vsync: this,
    );
    _categoryTabController.addListener(() {
      setState(() {
        _selectedCategoryIndex = _categoryTabController.index;
      });
    });

    _menuSubscription = MenuRepository.streamMenuItems().listen((items) {
      if (!mounted) {
        return;
      }

      final updatedCategories = _buildCategoriesFromMenu(items);

      setState(() {
        _menu = items;
        if (_areCategoriesDifferent(_menuCategories, updatedCategories)) {
          _menuCategories = updatedCategories;
          final nextIndex = _selectedCategoryIndex.clamp(0, _menuCategories.length - 1);
          _selectedCategoryIndex = nextIndex;

          _categoryTabController.dispose();
          _categoryTabController = TabController(
            length: _menuCategories.length,
            vsync: this,
            initialIndex: nextIndex,
          );
          _categoryTabController.addListener(() {
            setState(() {
              _selectedCategoryIndex = _categoryTabController.index;
            });
          });
        }

        _selectedQuantities.removeWhere(
          (menuItemId, _) => !_menu.any((item) => item.id == menuItemId),
        );
      });
    });
  }

  @override
  void dispose() {
    _menuSubscription?.cancel();
    _categoryTabController.dispose();
    super.dispose();
  }

  bool get _isAdmin {
    return MockAuthService.instance.canManageMenuAndViewAllOrders;
  }

  int get _totalItems {
    return _selectedQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  double get _totalAmount {
    var total = 0.0;
    for (final item in _menu) {
      final qty = _selectedQuantities[item.id] ?? 0;
      total += qty * item.price;
    }
    return total;
  }

  void _addItem(MenuItem item) {
    setState(() {
      _selectedQuantities[item.id] = (_selectedQuantities[item.id] ?? 0) + 1;
    });
  }

  void _removeItem(MenuItem item) {
    final currentQty = _selectedQuantities[item.id] ?? 0;
    if (currentQty <= 0) return;

    setState(() {
      final updatedQty = currentQty - 1;
      if (updatedQty == 0) {
        _selectedQuantities.remove(item.id);
      } else {
        _selectedQuantities[item.id] = updatedQty;
      }
    });
  }

  Future<void> _placeOrder() async {
    if (_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin accounts cannot place customer orders'),
        ),
      );
      return;
    }

    if (_totalItems == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to cart')),
      );
      return;
    }

    final currentUser = MockAuthService.instance.currentUser;
    if (currentUser == null) return;

    final order = OrderService.instance.placeOrder(
      userId: currentUser.email,
      userName: currentUser.name,
      quantities: _selectedQuantities,
      menuItems: _menu,
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF1A237E),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Order Placed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Token',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.token,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildOrderDetailRow('Items', '${order.totalItems}'),
              _buildOrderDetailRow(
                'Amount',
                'PKR ${order.totalAmount.toStringAsFixed(0)}',
              ),
              _buildOrderDetailRow(
                'Est. Time',
                '${order.estimatedMinutes} mins',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Track Order'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _selectedQuantities.clear();
      _selectedTabIndex = 2;
    });
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A237E),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    MockAuthService.instance.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Widget _buildMenuTab(String userName) {
    final categories = _menuCategories;
    final currentCategory = categories[_selectedCategoryIndex];
    final categoryItems = MenuRepository.getItemsByCategory(_menu, currentCategory);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          decoration: const BoxDecoration(
            color: Color(0xFF1A237E),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $userName!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'What would you like to eat today?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _categoryTabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabAlignment: TabAlignment.start,
                tabs: categories.map((c) => Tab(text: c)).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: categoryItems.length,
            itemBuilder: (context, index) {
              final item = categoryItems[index];
              final qty = _selectedQuantities[item.id] ?? 0;
              return _buildMenuItemCard(item, qty);
            },
          ),
        ),
      ],
    );
  }

  List<String> _buildCategoriesFromMenu(List<MenuItem> items) {
    final categoryOrder = <String>[];

    for (final category in MenuRepository.categories) {
      categoryOrder.add(category);
    }

    for (final item in items) {
      final category = item.category.trim();
      if (category.isNotEmpty && !categoryOrder.contains(category)) {
        categoryOrder.add(category);
      }
    }

    if (categoryOrder.isEmpty) {
      return List<String>.from(MenuRepository.categories);
    }

    return categoryOrder;
  }

  bool _areCategoriesDifferent(List<String> current, List<String> next) {
    if (current.length != next.length) {
      return true;
    }

    for (var index = 0; index < current.length; index++) {
      if (current[index] != next[index]) {
        return true;
      }
    }

    return false;
  }

  Widget _buildMenuItemCard(MenuItem item, int qty) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: _buildMenuImage(item.imageUrl),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF212121),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (qty > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'x$qty',
                            style: const TextStyle(
                              color: Color(0xFF212121),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          'PKR ${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00C37A),
                          ),
                        ),
                      ),
                      Material(
                        color: const Color(0xFFF4B236),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _addItem(item),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuImage(String imageUrl) {
    final trimmedUrl = imageUrl.trim();

    if (trimmedUrl.isEmpty) {
      return _buildMenuImageFallback();
    }

    final isNetworkImage =
        trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://');
    if (isNetworkImage) {
      return Image.network(
        Uri.encodeFull(trimmedUrl),
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildMenuImageFallback(),
      );
    }

    return Image.asset(
      trimmedUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildMenuImageFallback(),
    );
  }

  Widget _buildMenuImageFallback() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.fastfood, size: 36, color: Colors.grey),
      ),
    );
  }

  Widget _buildCartTab() {
    final selectedItems = _menu
        .where((item) => (_selectedQuantities[item.id] ?? 0) > 0)
        .toList();

    if (selectedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items from the menu',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => setState(() => _selectedTabIndex = 0),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Browse Menu'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF1A237E),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Cart',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${selectedItems.length} items',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: selectedItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = selectedItems[index];
              final qty = _selectedQuantities[item.id] ?? 0;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(
                                0xFF1A237E,
                              ).withValues(alpha: 0.4),
                              child: const Icon(Icons.restaurant),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PKR ${(item.price * qty).toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF1A237E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                            onPressed: () => _removeItem(item),
                            icon: const Icon(Icons.remove, size: 18),
                          ),
                          Text(
                            '$qty',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                            onPressed: () => _addItem(item),
                            icon: const Icon(Icons.add, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal'),
                  Text(
                    'PKR ${_totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Est. Pickup Time'),
                  Text(
                    '${10 + (_totalItems * 3)} mins',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _placeOrder,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Place Order  •  PKR ${_totalAmount.toStringAsFixed(0)}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    final currentUser = MockAuthService.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    final userOrders = OrderService.instance
        .getOrdersByUserId(currentUser.email)
        .reversed
        .toList();

    final currentToken = OrderService.instance.currentServingToken;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF1A237E),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Status',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              if (currentToken != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Now Serving',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Token #$currentToken',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: userOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No orders yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your orders will appear here',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: userOrders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = userOrders[index];
                    return _buildOrderCard(order);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order) {
    Color statusColor;
    IconData statusIcon;

    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case OrderStatus.preparing:
        statusColor = Colors.blue;
        statusIcon = Icons.restaurant;
        break;
      case OrderStatus.ready:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case OrderStatus.completed:
        statusColor = Colors.grey;
        statusIcon = Icons.done_all;
        break;
    }

    final waitTime = OrderService.instance.getEstimatedWaitTime(order.token);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${order.token}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.totalItems} items',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'PKR ${order.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      order.statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.status != OrderStatus.completed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: Color(0xFF1A237E),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated wait: $waitTime mins',
                    style: const TextStyle(
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountTab(String userName) {
    final currentUser = MockAuthService.instance.currentUser;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?.email ?? '',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentUser?.role ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSettingsSection('Role Selection', [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Switch Account Role',
                          style: TextStyle(
                            color: Color(0xFF1A237E),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: currentUser?.role ?? 'Student',
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF1A237E)),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: Color(0xFF1A237E),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1A237E),
                                width: 2,
                              ),
                            ),
                          ),
                          items: ['Student', 'Faculty', 'Admin'].map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(
                                role,
                                style: const TextStyle(
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && currentUser != null) {
                              setState(() {
                                // Update current user role
                                MockAuthService.instance.updateUserRole(
                                  currentUser.email,
                                  value,
                                );
                                // Admin has 3 tabs (0..2). If currently on student Account tab index 3,
                                // move to admin Account tab index 2 to avoid invalid NavigationBar index.
                                if (value == 'Admin' && _selectedTabIndex > 2) {
                                  _selectedTabIndex = 2;
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Role changed to $value'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSettingsSection('Notifications', [
                  SwitchListTile(
                    value: _orderAlerts,
                    onChanged: (value) => setState(() => _orderAlerts = value),
                    title: const Text('Order Alerts'),
                    subtitle: const Text('Get status and token updates'),
                    secondary: const Icon(Icons.notifications_outlined),
                  ),
                  SwitchListTile(
                    value: _emailReceipts,
                    onChanged: (value) =>
                        setState(() => _emailReceipts = value),
                    title: const Text('Email Receipts'),
                    subtitle: const Text('Receive receipts on email'),
                    secondary: const Icon(Icons.email_outlined),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSettingsSection('Account', [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Profile Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.profileSettings),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.changePassword),
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.helpSupport),
                  ),
                  if (MockAuthService.instance.canManageMenuAndViewAllOrders)
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined),
                      title: const Text('Admin Panel'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.admin),
                    ),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHomeTab(String userName) {
    final orderService = OrderService.instance;
    final totalOrders = orderService.allOrders.length;
    final activeOrders = orderService.activeOrders.length;
    final currentToken = orderService.currentServingToken ?? '-';

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Welcome back, $userName',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildAdminStatCard(
                        title: 'Total Orders',
                        value: '$totalOrders',
                        icon: Icons.shopping_bag_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAdminStatCard(
                        title: 'Active Tokens',
                        value: '$activeOrders',
                        icon: Icons.confirmation_number_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAdminStatCard(
                  title: 'Now Serving',
                  value: 'Token $currentToken',
                  icon: Icons.campaign_outlined,
                ),
                const SizedBox(height: 16),
                _buildSettingsSection('System Activity', [
                  ListTile(
                    leading: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF1A237E),
                    ),
                    title: const Text('Inventory items'),
                    subtitle: Text(
                      '${_menu.length} items configured',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.playlist_add_check_circle_outlined,
                      color: Color(0xFF1A237E),
                    ),
                    title: const Text('Completed orders'),
                    subtitle: Text(
                      '${orderService.completedOrders.length} completed today',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFF1A237E),
                    ),
                    title: const Text('Pending queue'),
                    subtitle: Text(
                      '${orderService.activeOrders.length} currently in queue',
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.admin),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Open Admin Management'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminManagementTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSettingsSection('Inventory Management', [
            ListTile(
              leading: const Icon(
                Icons.add_box_outlined,
                color: Color(0xFF1A237E),
              ),
              title: const Text('Add Items'),
              subtitle: const Text('Create new products for canteen menu'),
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF1A237E),
              ),
              title: const Text('Update Items'),
              subtitle: const Text('Edit name, price, category, and image'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Color(0xFF1A237E),
              ),
              title: const Text('Delete Items'),
              subtitle: const Text('Remove unavailable inventory items'),
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.admin),
              child: const Text('Manage Inventory & Orders'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1A237E)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A237E),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = MockAuthService.instance.currentUser;
    final userName = currentUser?.name ?? 'User';
    final isAdmin = MockAuthService.instance.canManageMenuAndViewAllOrders;
    final selectedNavIndex = isAdmin
        ? (_selectedTabIndex > 2 ? 2 : _selectedTabIndex)
        : _selectedTabIndex;

    Widget activeTab;
    if (isAdmin) {
      switch (_selectedTabIndex) {
        case 0:
          activeTab = _buildAdminHomeTab(userName);
          break;
        case 1:
          activeTab = _buildAdminManagementTab();
          break;
        default:
          activeTab = _buildAccountTab(userName);
      }
    } else {
      switch (_selectedTabIndex) {
        case 0:
          activeTab = _buildMenuTab(userName);
          break;
        case 1:
          activeTab = _buildCartTab();
          break;
        case 2:
          activeTab = _buildOrdersTab();
          break;
        default:
          activeTab = _buildAccountTab(userName);
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(child: activeTab),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedNavIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedTabIndex = index),
        destinations: isAdmin
            ? const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: 'Inventory',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Account',
                ),
              ]
            : [
                const NavigationDestination(
                  icon: Icon(Icons.restaurant_menu),
                  label: 'Menu',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: _totalItems > 0,
                    label: Text('$_totalItems'),
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: _totalItems > 0,
                    label: Text('$_totalItems'),
                    child: const Icon(Icons.shopping_cart),
                  ),
                  label: 'Cart',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Orders',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Account',
                ),
              ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pre_order_system/app/routes.dart';
import 'package:pre_order_system/features/orders/token_service.dart';
import 'package:pre_order_system/shared/models/menu_item.dart';
import 'package:pre_order_system/shared/services/menu_repository.dart';
import 'package:pre_order_system/shared/services/mock_auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<MenuItem> _menu = MenuRepository.menu;
  final Map<String, int> _selectedQuantities = {};
  int _selectedTabIndex = 0;
  String? _lastOrderToken;
  double _lastOrderAmount = 0;
  int _lastOrderItems = 0;
  int _lastPickupMinutes = 0;
  bool _orderAlerts = true;
  bool _emailReceipts = true;

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
    if (currentQty <= 0) {
      return;
    }

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
    if (_totalItems == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to cart')),
      );
      return;
    }

    final token = TokenService.instance.generateDailyToken();
    final orderAmount = _totalAmount;
    final orderItems = _totalItems;
    final pickupMinutes = 12 + (orderItems * 2);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Order Placed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your order was placed successfully.'),
              const SizedBox(height: 8),
              Text('Token Number: $token'),
              Text('Items: $orderItems'),
              Text('Amount: PKR ${orderAmount.toStringAsFixed(0)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _lastOrderToken = token;
      _lastOrderAmount = orderAmount;
      _lastOrderItems = orderItems;
      _lastPickupMinutes = pickupMinutes;
      _selectedQuantities.clear();
      _selectedTabIndex = 2;
    });
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '👋 Hi $userName!',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
              ),
              const CircleAvatar(radius: 18, child: Icon(Icons.person)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: _menu.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _menu[index];
              final qty = _selectedQuantities[item.id] ?? 0;

              return Container(
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 22,
                                color: Color(0xFF42348B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'PKR ${item.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _removeItem(item),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('$qty'),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _addItem(item),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      child: SizedBox(
                        width: 130,
                        height: 110,
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const ColoredBox(
                              color: Color(0xFFD9D9D9),
                              child: Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
            const Text('Cart is empty. Add items from Menu.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
              child: const Text('Go to Menu'),
            ),
          ],
        ),
      );
    }

    const restaurantName = 'Lahore Campus Canteen';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Check Out',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Restaurant: $restaurantName',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            itemCount: selectedItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = selectedItems[index];
              final qty = _selectedQuantities[item.id] ?? 0;

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const ColoredBox(
                              color: Color(0xFFD9D9D9),
                              child: Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PKR ${item.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _removeItem(item),
                            child: Text(
                              '−',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: Text(
                              '$qty',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _addItem(item),
                            child: Text(
                              '+',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            children: [
              Divider(color: Theme.of(context).colorScheme.primary),
              Row(
                children: [
                  const Expanded(child: Text('Total Price (Without tax)')),
                  Text(
                    'PKR ${_totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Expanded(child: Text('Pickup In-Time (Estd)')),
                  Text(
                    '${12 + (_totalItems * 2)}mins',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _placeOrder,
                  child: const Text('Order Now'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTab(String userName) {
    final currentUser = MockAuthService.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 42,
            child: Icon(Icons.person, size: 40),
          ),
          const SizedBox(height: 18),
          Text(
            userName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            currentUser?.email ?? '',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            currentUser?.role ?? '',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Order Token',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (_lastOrderToken == null)
                    const Text('No order placed yet.')
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Token: $_lastOrderToken'),
                        Text('Items: $_lastOrderItems'),
                        Text('Amount: PKR ${_lastOrderAmount.toStringAsFixed(0)}'),
                        Text('Pickup In-Time: $_lastPickupMinutes mins'),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                SwitchListTile(
                  value: _orderAlerts,
                  onChanged: (value) {
                    setState(() {
                      _orderAlerts = value;
                    });
                  },
                  title: const Text('Order Alerts'),
                  subtitle: const Text('Get status and token updates'),
                ),
                SwitchListTile(
                  value: _emailReceipts,
                  onChanged: (value) {
                    setState(() {
                      _emailReceipts = value;
                    });
                  },
                  title: const Text('Email Receipts'),
                  subtitle: const Text('Receive receipts on email'),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profile Settings'),
                  subtitle: const Text('Update your basic details'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  subtitle: const Text('Manage account security'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  subtitle: const Text('Contact canteen support team'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = MockAuthService.instance.currentUser;
    final userName = currentUser?.name ?? 'User';

    Widget activeTab;
    if (_selectedTabIndex == 0) {
      activeTab = _buildMenuTab(userName);
    } else if (_selectedTabIndex == 1) {
      activeTab = _buildCartTab();
    } else {
      activeTab = _buildAccountTab(userName);
    }

    return Scaffold(
      body: SafeArea(child: activeTab),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

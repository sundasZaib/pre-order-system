import 'package:flutter/material.dart';
import 'package:pre_order_system/shared/models/order.dart';
import 'package:pre_order_system/shared/services/order_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateOrderStatus(Order order, OrderStatus newStatus) {
    setState(() {
      OrderService.instance.updateOrderStatus(order.id, newStatus);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order #${order.token} marked as ${newStatus.name}'),
        backgroundColor: const Color(0xFF1A237E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService.instance;
    final pendingOrders = orderService.pendingOrders;
    final preparingOrders = orderService.preparingOrders;
    final readyOrders = orderService.readyOrders;
    final allOrders = orderService.allOrders;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Pending (${pendingOrders.length})'),
            Tab(text: 'Preparing (${preparingOrders.length})'),
            Tab(text: 'Ready (${readyOrders.length})'),
            Tab(text: 'All (${allOrders.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(pendingOrders, 'pending'),
          _buildOrderList(preparingOrders, 'preparing'),
          _buildOrderList(readyOrders, 'ready'),
          _buildOrderList(allOrders, 'all'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final pending = orderService.pendingOrders;
          if (pending.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No pending orders')),
            );
            return;
          }
          _updateOrderStatus(pending.first, OrderStatus.preparing);
        },
        backgroundColor: const Color(0xFF1A237E),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Call Next'),
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders, String type) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No $type orders',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildAdminOrderCard(order);
      },
    );
  }

  Widget _buildAdminOrderCard(Order order) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${order.token}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.totalItems} items  •  PKR ${order.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Order Items:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(child: Text(item.menuItem.name)),
                Text('PKR ${item.total.toStringAsFixed(0)}'),
              ],
            ),
          )),
          const SizedBox(height: 16),
          if (order.status != OrderStatus.completed)
            Row(
              children: [
                if (order.status == OrderStatus.pending)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _updateOrderStatus(order, OrderStatus.preparing),
                      icon: const Icon(Icons.restaurant),
                      label: const Text('Start Preparing'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (order.status == OrderStatus.preparing) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _updateOrderStatus(order, OrderStatus.ready),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark Ready'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
                if (order.status == OrderStatus.ready) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _updateOrderStatus(order, OrderStatus.completed),
                      icon: const Icon(Icons.done_all),
                      label: const Text('Complete Order'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

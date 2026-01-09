import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import 'admin_inventory_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_statistics_screen.dart';
import 'admin_settings_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final AppUser user;
  final LocalStorageService storageService;
  final VoidCallback onSignOut;

  const AdminHomeScreen({
    super.key,
    required this.user,
    required this.storageService,
    required this.onSignOut,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  List<Product> _products = [];
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final products = await widget.storageService.getProducts();
    final orders = await widget.storageService.getOrders();
    setState(() {
      _products = products;
      _orders = orders;
      _isLoading = false;
    });
  }

  List<Product> get _lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  List<Order> get _pendingOrders =>
      _orders.where((o) => o.status != OrderStatus.delivered && 
                          o.status != OrderStatus.cancelled).toList();

  double get _todayRevenue {
    final today = DateTime.now();
    return _orders
        .where((o) =>
            o.status == OrderStatus.delivered &&
            o.deliveredAt != null &&
            o.deliveredAt!.day == today.day &&
            o.deliveredAt!.month == today.month &&
            o.deliveredAt!.year == today.year)
        .fold(0.0, (sum, o) => sum + o.total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboardTab(),
                AdminInventoryScreen(
                  storageService: widget.storageService,
                  onRefresh: _loadData,
                ),
                AdminOrdersScreen(
                  storageService: widget.storageService,
                  onRefresh: _loadData,
                ),
                AdminStatisticsScreen(
                  storageService: widget.storageService,
                ),
                AdminSettingsScreen(
                  onSignOut: widget.onSignOut,
                ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index > 0) _loadData();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _lowStockProducts.isNotEmpty,
              label: Text('${_lowStockProducts.length}'),
              child: const Icon(Icons.inventory_2_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _lowStockProducts.isNotEmpty,
              label: Text('${_lowStockProducts.length}'),
              child: const Icon(Icons.inventory_2),
            ),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _pendingOrders.isNotEmpty,
              label: Text('${_pendingOrders.length}'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _pendingOrders.isNotEmpty,
              label: Text('${_pendingOrders.length}'),
              child: const Icon(Icons.receipt_long),
            ),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Admin Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: widget.onSignOut,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  AppCard(
                    backgroundColor: AppTheme.primaryPastel.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryPastel,
                          child: Text(
                            widget.user.name.isNotEmpty
                                ? widget.user.name[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                widget.user.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.attach_money,
                          label: "Today's Revenue",
                          value: '₹${_todayRevenue.toStringAsFixed(0)}',
                          color: AppTheme.successPastel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.pending_actions,
                          label: 'Pending Orders',
                          value: '${_pendingOrders.length}',
                          color: AppTheme.warningPastel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.inventory,
                          label: 'Total Products',
                          value: '${_products.length}',
                          color: AppTheme.secondaryPastel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.warning_amber,
                          label: 'Low Stock',
                          value: '${_lowStockProducts.length}',
                          color: AppTheme.errorPastel,
                        ),
                      ),
                    ],
                  ),

                  // Low Stock Alerts
                  if (_lowStockProducts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Stock Alerts'),
                    const SizedBox(height: 8),
                    ..._lowStockProducts.take(3).map((product) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            backgroundColor: product.isOutOfStock
                                ? AppTheme.errorPastel.withValues(alpha: 0.2)
                                : AppTheme.warningPastel.withValues(alpha: 0.2),
                            onTap: () {
                              setState(() => _currentIndex = 1);
                            },
                            child: Row(
                              children: [
                                Icon(
                                  product.isOutOfStock
                                      ? Icons.error_outline
                                      : Icons.warning_amber_outlined,
                                  color: product.isOutOfStock
                                      ? (Theme.of(context).brightness == Brightness.dark ? AppTheme.redDark : AppTheme.errorPastel)
                                      : (Theme.of(context).brightness == Brightness.dark ? AppTheme.yellowDark : AppTheme.warningPastel),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        product.isOutOfStock
                                            ? 'Out of stock!'
                                            : 'Only ${product.stockQuantity} left',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        )),
                  ],

                  // Recent Orders
                  if (_pendingOrders.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Recent Orders',
                      actionLabel: 'View All',
                      onAction: () => setState(() => _currentIndex = 2),
                    ),
                    const SizedBox(height: 8),
                    ..._pendingOrders.take(3).map((order) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OrderCard(
                            order: order,
                            isAdmin: true,
                            onShareLocation: () => _shareLocation(order),
                            onMarkDelivered: () => _markDelivered(order),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareLocation(Order order) async {
    final url = order.liveLocationUrl;
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location link copied: ${order.deliveryAddress.fullAddress}'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _markDelivered(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Delivered?'),
        content: Text(
            'Mark order #${order.id.substring(0, 8).toUpperCase()} as delivered?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedOrder = order.copyWith(
        status: OrderStatus.delivered,
        deliveredAt: DateTime.now(),
      );
      await widget.storageService.updateOrder(updatedOrder);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked as delivered')),
        );
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

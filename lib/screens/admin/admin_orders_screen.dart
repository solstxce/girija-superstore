import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class AdminOrdersScreen extends StatefulWidget {
  final LocalStorageService storageService;
  final VoidCallback onRefresh;

  const AdminOrdersScreen({
    super.key,
    required this.storageService,
    required this.onRefresh,
  });

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await widget.storageService.getOrders();
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  List<Order> get _pendingOrders => _orders
      .where((o) =>
          o.status == OrderStatus.pending ||
          o.status == OrderStatus.confirmed ||
          o.status == OrderStatus.processing)
      .toList();

  List<Order> get _activeOrders =>
      _orders.where((o) => o.status == OrderStatus.outForDelivery).toList();

  List<Order> get _completedOrders => _orders
      .where((o) =>
          o.status == OrderStatus.delivered ||
          o.status == OrderStatus.cancelled)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Badge(
                isLabelVisible: _pendingOrders.isNotEmpty,
                label: Text('${_pendingOrders.length}'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Pending'),
                ),
              ),
            ),
            Tab(
              child: Badge(
                isLabelVisible: _activeOrders.isNotEmpty,
                label: Text('${_activeOrders.length}'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Active'),
                ),
              ),
            ),
            const Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(_pendingOrders, 'No pending orders'),
                _buildOrdersList(_activeOrders, 'No active deliveries'),
                _buildOrdersList(_completedOrders, 'No completed orders'),
              ],
            ),
    );
  }

  Widget _buildOrdersList(List<Order> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: emptyMessage,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            order: order,
            isAdmin: true,
            onTap: () => _showOrderDetails(order),
            onShareLocation: () => _shareLocation(order),
            onMarkDelivered: order.status != OrderStatus.delivered
                ? () => _markDelivered(order)
                : null,
          );
        },
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${order.id.substring(0, 8).toUpperCase()}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              _formatDateTime(order.createdAt),
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusDropdown(
                        currentStatus: order.status,
                        onChanged: (newStatus) async {
                          final updated = order.copyWith(
                            status: newStatus,
                            deliveredAt: newStatus == OrderStatus.delivered
                                ? DateTime.now()
                                : order.deliveredAt,
                          );
                          await widget.storageService.updateOrder(updated);
                          widget.onRefresh();
                          await _loadOrders();
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Customer Info
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 18),
                            const SizedBox(width: 8),
                            Text(order.userName),
                          ],
                        ),
                        if (order.userPhone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(order.userPhone),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(order.deliveryAddress.fullAddress),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Share Location',
                                isOutlined: true,
                                icon: Icons.share_location,
                                onPressed: () => _shareLocation(order),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Items
                  const Text(
                    'Order Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ...order.items.map((item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${item.quantity}x',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(item.product.name),
                              subtitle: Text(
                                '₹${item.product.discountedPrice.toStringAsFixed(0)} each',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                '₹${item.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )),
                        const Divider(),
                        _SummaryRow(label: 'Subtotal', value: order.subtotal),
                        if (order.discount > 0)
                          _SummaryRow(
                            label: 'Discount',
                            value: -order.discount,
                            isDiscount: true,
                          ),
                        _SummaryRow(
                          label: 'Delivery',
                          value: order.deliveryFee,
                          freeLabel: order.deliveryFee == 0 ? 'FREE' : null,
                        ),
                        _SummaryRow(
                          label: 'Total',
                          value: order.total,
                          isTotal: true,
                        ),
                        if (order.notes != null && order.notes!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          AppCard(
                            backgroundColor: AppTheme.warningPastel.withValues(alpha: 0.2),
                            child: Row(
                              children: [
                                const Icon(Icons.note_outlined),
                                const SizedBox(width: 12),
                                Expanded(child: Text(order.notes!)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (order.status != OrderStatus.delivered &&
                      order.status != OrderStatus.cancelled)
                    AppButton(
                      label: 'Mark as Delivered',
                      icon: Icons.check_circle_outline,
                      width: double.infinity,
                      onPressed: () {
                        Navigator.pop(context);
                        _markDelivered(order);
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _shareLocation(Order order) async {
    final url = order.liveLocationUrl;
    await Clipboard.setData(ClipboardData(text: url));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Location link copied!'),
              Text(
                order.deliveryAddress.fullAddress,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
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
            'Confirm that order #${order.id.substring(0, 8).toUpperCase()} has been delivered to ${order.userName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Delivery'),
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
      widget.onRefresh();
      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked as delivered!')),
        );
      }
    }
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $ampm';
  }
}

class _StatusDropdown extends StatelessWidget {
  final OrderStatus currentStatus;
  final ValueChanged<OrderStatus> onChanged;

  const _StatusDropdown({
    required this.currentStatus,
    required this.onChanged,
  });

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppTheme.warningPastel;
      case OrderStatus.confirmed:
        return AppTheme.secondaryPastel;
      case OrderStatus.processing:
        return AppTheme.primaryPastel;
      case OrderStatus.outForDelivery:
        return AppTheme.accentPastel;
      case OrderStatus.delivered:
        return AppTheme.successPastel;
      case OrderStatus.cancelled:
        return AppTheme.errorPastel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<OrderStatus>(
      initialValue: currentStatus,
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getStatusColor(currentStatus).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _getStatusColor(currentStatus)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentStatus.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) => OrderStatus.values
          .map((status) => PopupMenuItem(
                value: status,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(status.displayName),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final bool isDiscount;
  final String? freeLabel;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isDiscount = false,
    this.freeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
          Text(
            freeLabel ?? '${isDiscount ? '-' : ''}₹${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isDiscount
                  ? (Theme.of(context).brightness == Brightness.dark ? AppTheme.greenDark : AppTheme.successPastel)
                  : freeLabel != null
                      ? (Theme.of(context).brightness == Brightness.dark ? AppTheme.greenDark : AppTheme.successPastel)
                      : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

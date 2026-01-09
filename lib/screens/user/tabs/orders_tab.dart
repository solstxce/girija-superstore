import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/widgets.dart';
import 'cart_tab.dart';

class OrdersTab extends StatelessWidget {
  final List<Order> orders;
  final Function(Order) onOrderTap;

  const OrdersTab({
    super.key,
    required this.orders,
    required this.onOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Orders')),
      body: orders.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Your order history will appear here',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderCard(
                  order: order,
                  onTap: () => onOrderTap(order),
                );
              },
            ),
    );
  }
}

void showOrderDetailsSheet(BuildContext context, Order order) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Order #${order.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            StatusBadge(
              label: order.status.displayName,
              color: AppTheme.primaryPastel,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  ...order.items.map((item) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.backgroundDark
                              : AppTheme.backgroundLight,
                          child: Text('${item.quantity}x'),
                        ),
                        title: Text(item.product.name),
                        trailing: Text(
                          '₹${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      )),
                  const Divider(),
                  SummaryRow(label: 'Subtotal', value: order.subtotal),
                  if (order.discount > 0)
                    SummaryRow(
                      label: 'Discount',
                      value: -order.discount,
                      isDiscount: true,
                    ),
                  SummaryRow(label: 'Delivery', value: order.deliveryFee),
                  SummaryRow(
                    label: 'Total',
                    value: order.total,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

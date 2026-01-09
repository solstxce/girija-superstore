import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/widgets.dart';

class CartTab extends StatelessWidget {
  final List<CartItem> cart;
  final Function(CartItem, int) onQuantityChanged;
  final VoidCallback onPlaceOrder;

  const CartTab({
    super.key,
    required this.cart,
    required this.onQuantityChanged,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.fold(0.0, (sum, item) => sum + item.totalPrice);
    final savings = cart.fold(0.0, (sum, item) => sum + item.savings);
    final deliveryFee = subtotal >= 500 ? 0.0 : 30.0;
    final total = subtotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: cart.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Add items from the shop to get started',
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return CartItemCard(
                        item: item,
                        onQuantityChanged: (qty) => onQuantityChanged(item, qty),
                        onRemove: () => onQuantityChanged(item, 0),
                      );
                    },
                  ),
                ),
                // Order Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        SummaryRow(label: 'Subtotal', value: subtotal),
                        if (savings > 0)
                          SummaryRow(
                            label: 'Discount',
                            value: -savings,
                            isDiscount: true,
                          ),
                        SummaryRow(
                          label: 'Delivery',
                          value: deliveryFee,
                          freeLabel: subtotal >= 500 ? 'FREE' : null,
                        ),
                        const Divider(height: 16),
                        SummaryRow(
                          label: 'Total',
                          value: total,
                          isTotal: true,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Place Order',
                          onPressed: onPlaceOrder,
                          width: double.infinity,
                        ),
                        if (subtotal < 500)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Add ₹${(500 - subtotal).toStringAsFixed(0)} more for free delivery',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.product.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.shopping_basket_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.product.discountedPrice.toStringAsFixed(0)} each',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                if (item.savings > 0)
                  Text(
                    'You save ₹${item.savings.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.greenDark : AppTheme.successPastel,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.totalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              QuantitySelector(
                quantity: item.quantity,
                onChanged: onQuantityChanged,
                min: 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final bool isDiscount;
  final String? freeLabel;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isDiscount = false,
    this.freeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final secondaryColor = Theme.of(context).textTheme.bodySmall?.color;
    
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
              color: isTotal ? textColor : secondaryColor,
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
                      : textColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final bool isAdmin;
  final VoidCallback? onShareLocation;
  final VoidCallback? onMarkDelivered;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.isAdmin = false,
    this.onShareLocation,
    this.onMarkDelivered,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: order.status.displayName,
                    color: _getStatusColor(order.status),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Items summary
              Text(
                '${order.totalItems} item${order.totalItems > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.items.take(3).map((e) => e.product.name).join(', ') +
                    (order.items.length > 3
                        ? ' +${order.items.length - 3} more'
                        : ''),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Total and actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '₹${order.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isAdmin && order.status != OrderStatus.delivered) ...[
                    if (onShareLocation != null)
                      IconButton(
                        onPressed: onShareLocation,
                        icon: const Icon(Icons.share_location_outlined),
                        tooltip: 'Share Location',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.secondaryPastel,
                          foregroundColor: AppTheme.textPrimary,
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (onMarkDelivered != null)
                      IconButton(
                        onPressed: onMarkDelivered,
                        icon: const Icon(Icons.check_circle_outline),
                        tooltip: 'Mark Delivered',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.successPastel,
                          foregroundColor: AppTheme.textPrimary,
                        ),
                      ),
                  ],
                ],
              ),
              // Admin - Customer Info
              if (isAdmin) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.userName,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.deliveryAddress.fullAddress,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

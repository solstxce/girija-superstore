import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool showStock;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.showStock = false,
  });

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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
                        child: product.imageUrl.isNotEmpty
                            ? Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                                ),
                              )
                            : Icon(
                                Icons.shopping_basket_outlined,
                                size: 48,
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                              ),
                      ),
                      if (product.discountPercent > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.errorPastel,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${product.discountPercent.toInt()}% OFF',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      if (showStock && product.isLowStock)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: product.isOutOfStock
                                  ? AppTheme.errorPastel
                                  : AppTheme.warningPastel,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.isOutOfStock
                                  ? 'Out of Stock'
                                  : 'Low Stock',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.discountPercent > 0)
                                  Text(
                                    '₹${product.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  '₹${product.discountedPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onAddToCart != null && !product.isOutOfStock)
                            IconButton(
                              onPressed: onAddToCart,
                              icon: const Icon(Icons.add_shopping_cart_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primaryPastel,
                                foregroundColor: AppTheme.textPrimary,
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
        ),
      ),
    );
  }
}

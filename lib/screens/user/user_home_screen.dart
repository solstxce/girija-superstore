import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import 'tabs/shop_tab.dart';
import 'tabs/cart_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/settings_tab.dart';

class UserHomeScreen extends StatefulWidget {
  final AppUser user;
  final LocalStorageService storageService;
  final VoidCallback onSignOut;

  const UserHomeScreen({
    super.key,
    required this.user,
    required this.storageService,
    required this.onSignOut,
  });

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  List<Product> _products = [];
  List<CartItem> _cart = [];
  List<Order> _orders = [];
  List<Address> _addresses = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final products = await widget.storageService.getProducts();
    final cart = await widget.storageService.getCart();
    final orders = await widget.storageService.getOrdersByUserId(widget.user.id);
    final addresses = await widget.storageService.getAddresses();

    setState(() {
      _products = products;
      _cart = cart;
      _orders = orders;
      _addresses = addresses;
    });
  }

  List<String> get _categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<Product> get _filteredProducts {
    var filtered = _products.where((p) => !p.isOutOfStock).toList();

    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    return filtered;
  }

  Future<void> _addToCart(Product product) async {
    final existingIndex = _cart.indexWhere((c) => c.product.id == product.id);

    if (existingIndex != -1) {
      _cart[existingIndex].quantity++;
    } else {
      _cart.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: product,
        quantity: 1,
      ));
    }

    await widget.storageService.saveCart(_cart);
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _updateCartQuantity(CartItem item, int quantity) async {
    if (quantity <= 0) {
      _cart.removeWhere((c) => c.id == item.id);
    } else {
      item.quantity = quantity;
    }
    await widget.storageService.saveCart(_cart);
    setState(() {});
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;
    if (_addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a delivery address first')),
      );
      return;
    }

    final defaultAddress =
        _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first);

    final subtotal = _cart.fold(0.0, (sum, item) => sum + item.totalPrice);
    final discount = _cart.fold(0.0, (sum, item) => sum + item.savings);
    const deliveryFee = 30.0;
    final total = subtotal + deliveryFee;

    final order = Order(
      id: 'ord${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.user.id,
      userName: widget.user.name,
      userPhone: widget.user.phone,
      items: List.from(_cart),
      deliveryAddress: defaultAddress,
      userLatitude: defaultAddress.latitude,
      userLongitude: defaultAddress.longitude,
      status: OrderStatus.pending,
      subtotal: subtotal,
      discount: discount,
      deliveryFee: subtotal >= 500 ? 0 : deliveryFee,
      total: subtotal >= 500 ? subtotal : total,
    );

    await widget.storageService.addOrder(order);
    await widget.storageService.clearCart();

    // Update stock
    final products = await widget.storageService.getProducts();
    for (final cartItem in _cart) {
      final productIndex = products.indexWhere((p) => p.id == cartItem.product.id);
      if (productIndex != -1) {
        final updated = products[productIndex].copyWith(
          stockQuantity: products[productIndex].stockQuantity - cartItem.quantity,
        );
        products[productIndex] = updated;
      }
    }
    await widget.storageService.saveProducts(products);

    _cart.clear();
    _orders.insert(0, order);
    _products = products;
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
    }
  }

  void _showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(
        product: product,
        onAddToCart: () {
          _addToCart(product);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showOrderDetailsSheet(context, order);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ShopTab(
            products: _products,
            filteredProducts: _filteredProducts,
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) => setState(() => _selectedCategory = category),
            onProductTap: _showProductDetails,
            onAddToCart: _addToCart,
          ),
          CartTab(
            cart: _cart,
            onQuantityChanged: _updateCartQuantity,
            onPlaceOrder: _placeOrder,
          ),
          OrdersTab(
            orders: _orders,
            onOrderTap: _showOrderDetails,
          ),
          ProfileTab(
            user: widget.user,
            addresses: _addresses,
            storageService: widget.storageService,
            onSignOut: widget.onSignOut,
            onDataChanged: _loadData,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _cart.isNotEmpty,
              label: Text('${_cart.length}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _cart.isNotEmpty,
              label: Text('${_cart.length}'),
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
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ProductDetailSheet extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductDetailSheet({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {}, // Prevent tap from closing when tapping on the sheet
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar and back button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Product Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 1.6,
                            child: Container(
                              color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
                              child: product.imageUrl.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.image_outlined,
                                        size: 60,
                                        color: AppTheme.textSecondary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.shopping_basket_outlined,
                                      size: 60,
                                      color: AppTheme.textSecondary,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Category
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.blueDark : AppTheme.primaryPastel,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.backgroundDark : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Product Name
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${product.discountedPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (product.discountPercent > 0) ...[
                              const SizedBox(width: 12),
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.redDark : AppTheme.errorPastel,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${product.discountPercent.toInt()}% OFF',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppTheme.backgroundDark : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Stock Status
                        Row(
                          children: [
                            Icon(
                              product.isOutOfStock
                                  ? Icons.cancel_outlined
                                  : Icons.check_circle_outline,
                              color: product.isOutOfStock 
                                  ? (Theme.of(context).brightness == Brightness.dark ? AppTheme.redDark : AppTheme.errorPastel)
                                  : (Theme.of(context).brightness == Brightness.dark ? AppTheme.greenDark : AppTheme.successPastel),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              product.isOutOfStock ? 'Out of Stock' : 'In Stock',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: product.isOutOfStock 
                                    ? (Theme.of(context).brightness == Brightness.dark ? AppTheme.redDark : AppTheme.errorPastel)
                                    : (Theme.of(context).brightness == Brightness.dark ? AppTheme.greenDark : AppTheme.successPastel),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Description (only visible when scrolled/expanded)
                        if (product.description.isNotEmpty) ...[
                          const Divider(),
                          const SizedBox(height: 12),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 80), // Space for button
                      ],
                    ),
                  ),
                  // Add to Cart Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                      border: Border(
                        top: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: SafeArea(
                      child: AppButton(
                        label: product.isOutOfStock ? 'Out of Stock' : 'Add to Cart',
                        onPressed: product.isOutOfStock ? null : onAddToCart,
                        width: double.infinity,
                        icon: product.isOutOfStock ? null : Icons.add_shopping_cart,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

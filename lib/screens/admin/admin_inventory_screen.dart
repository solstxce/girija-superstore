import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class AdminInventoryScreen extends StatefulWidget {
  final LocalStorageService storageService;
  final VoidCallback onRefresh;

  const AdminInventoryScreen({
    super.key,
    required this.storageService,
    required this.onRefresh,
  });

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  List<Product> _products = [];
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showLowStockOnly = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await widget.storageService.getProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  List<String> get _categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<Product> get _filteredProducts {
    var filtered = _products.toList();

    if (_showLowStockOnly) {
      filtered = filtered.where((p) => p.isLowStock).toList();
    }

    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.barcode.contains(_searchQuery))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
            onPressed: _showBarcodeScannerDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and Filters
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AppTextField(
                        hint: 'Search products or scan barcode...',
                        prefixIcon: const Icon(Icons.search),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: _selectedCategory == null && !_showLowStockOnly,
                              onSelected: (_) => setState(() {
                                _selectedCategory = null;
                                _showLowStockOnly = false;
                              }),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber, size: 16),
                                  SizedBox(width: 4),
                                  Text('Low Stock'),
                                ],
                              ),
                              selected: _showLowStockOnly,
                              selectedColor: AppTheme.warningPastel,
                              onSelected: (selected) => setState(() {
                                _showLowStockOnly = selected;
                                _selectedCategory = null;
                              }),
                            ),
                            const SizedBox(width: 8),
                            ..._categories.map(
                              (cat) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(cat),
                                  selected: _selectedCategory == cat,
                                  onSelected: (_) => setState(() {
                                    _selectedCategory =
                                        _selectedCategory == cat ? null : cat;
                                    _showLowStockOnly = false;
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Products List
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No products found',
                          subtitle: 'Add products to your inventory',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredProducts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _InventoryProductCard(
                              product: product,
                              onTap: () => _showProductDetails(product),
                              onEdit: () => _showProductForm(product: product),
                              onAdjustStock: () => _showStockAdjustDialog(product),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  void _showBarcodeScannerDialog() {
    final barcodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan/Enter Barcode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 64,
                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Camera barcode scanning\ncoming soon!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Or enter barcode manually:'),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Enter barcode number',
              controller: barcodeController,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final barcode = barcodeController.text.trim();
              Navigator.pop(context);

              if (barcode.isNotEmpty) {
                final existingProduct = _products.firstWhere(
                  (p) => p.barcode == barcode,
                  orElse: () => Product(
                    id: '',
                    name: '',
                    price: 0,
                    stockQuantity: 0,
                  ),
                );

                if (existingProduct.id.isNotEmpty) {
                  _showProductDetails(existingProduct);
                } else {
                  _showProductForm(initialBarcode: barcode);
                }
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: product.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(product.imageUrl, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.shopping_basket_outlined, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                          ),
                        ),
                        if (product.barcode.isNotEmpty)
                          Text(
                            'Barcode: ${product.barcode}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _DetailRow(label: 'Price', value: '₹${product.price.toStringAsFixed(2)}'),
                    if (product.discountPercent > 0)
                      _DetailRow(
                        label: 'Discount',
                        value: '${product.discountPercent}%',
                      ),
                    if (product.discountPercent > 0)
                      _DetailRow(
                        label: 'Discounted Price',
                        value: '₹${product.discountedPrice.toStringAsFixed(2)}',
                      ),
                    _DetailRow(
                      label: 'Stock Quantity',
                      value: '${product.stockQuantity}',
                      valueColor: product.isLowStock ? (Theme.of(context).brightness == Brightness.dark ? AppTheme.yellowDark : AppTheme.warningPastel) : null,
                    ),
                    _DetailRow(
                      label: 'Low Stock Threshold',
                      value: '${product.lowStockThreshold}',
                    ),
                    if (product.description.isNotEmpty)
                      _DetailRow(label: 'Description', value: product.description),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Adjust Stock',
                      isOutlined: true,
                      icon: Icons.inventory,
                      onPressed: () {
                        Navigator.pop(context);
                        _showStockAdjustDialog(product);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Edit',
                      icon: Icons.edit,
                      onPressed: () {
                        Navigator.pop(context);
                        _showProductForm(product: product);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductForm({Product? product, String? initialBarcode}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final barcodeController = TextEditingController(
        text: product?.barcode ?? initialBarcode ?? '');
    final priceController =
        TextEditingController(text: product?.price.toStringAsFixed(2) ?? '');
    final discountController = TextEditingController(
        text: product?.discountPercent.toStringAsFixed(0) ?? '0');
    final stockController =
        TextEditingController(text: product?.stockQuantity.toString() ?? '');
    final thresholdController = TextEditingController(
        text: product?.lowStockThreshold.toString() ?? '10');
    String category = product?.category ?? 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => DraggableScrollableSheet(
            initialChildSize: 0.8,
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
                        color: AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product == null ? 'Add Product' : 'Edit Product',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        AppTextField(
                          label: 'Product Name*',
                          controller: nameController,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Description',
                          controller: descController,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Barcode',
                          controller: barcodeController,
                          keyboardType: TextInputType.number,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () {
                              // Placeholder for barcode scanner
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Price*',
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('₹'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'Discount %',
                                controller: discountController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Stock Qty*',
                                controller: stockController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'Low Stock Alert',
                                controller: thresholdController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'General',
                            'Dairy',
                            'Bakery',
                            'Fruits',
                            'Vegetables',
                            'Grains',
                            'Oils',
                            'Meat',
                            'Beverages',
                            'Snacks',
                          ]
                              .map((cat) => ChoiceChip(
                                    label: Text(cat),
                                    selected: category == cat,
                                    onSelected: (_) =>
                                        setModalState(() => category = cat),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (product != null)
                        Expanded(
                          child: AppButton(
                            label: 'Delete',
                            isOutlined: true,
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Product?'),
                                  content: Text(
                                      'Are you sure you want to delete "${product.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.errorPastel,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                await widget.storageService
                                    .deleteProduct(product.id);
                                widget.onRefresh();
                                await _loadProducts();
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      if (product != null) const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Save',
                          onPressed: () async {
                            if (nameController.text.isEmpty ||
                                priceController.text.isEmpty ||
                                stockController.text.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill required fields'),
                                  ),
                                );
                              }
                              return;
                            }

                            final newProduct = Product(
                              id: product?.id ??
                                  'p${DateTime.now().millisecondsSinceEpoch}',
                              name: nameController.text,
                              description: descController.text,
                              barcode: barcodeController.text,
                              price: double.tryParse(priceController.text) ?? 0,
                              discountPercent:
                                  double.tryParse(discountController.text) ?? 0,
                              stockQuantity:
                                  int.tryParse(stockController.text) ?? 0,
                              lowStockThreshold:
                                  int.tryParse(thresholdController.text) ?? 10,
                              category: category,
                              createdAt: product?.createdAt,
                              updatedAt: DateTime.now(),
                            );

                            if (product != null) {
                              await widget.storageService
                                  .updateProduct(newProduct);
                            } else {
                              await widget.storageService.addProduct(newProduct);
                            }

                            widget.onRefresh();
                            await _loadProducts();
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showStockAdjustDialog(Product product) {
    final quantityController = TextEditingController();
    bool isAdding = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adjust Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'Current stock: ${product.stockQuantity}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 4),
                          Text('Add'),
                        ],
                      ),
                      selected: isAdding,
                      selectedColor: AppTheme.successPastel,
                      onSelected: (_) => setDialogState(() => isAdding = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.remove, size: 18),
                          SizedBox(width: 4),
                          Text('Remove'),
                        ],
                      ),
                      selected: !isAdding,
                      selectedColor: AppTheme.errorPastel,
                      onSelected: (_) => setDialogState(() => isAdding = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Quantity',
                controller: quantityController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(quantityController.text) ?? 0;
                if (qty <= 0) return;

                final newStock = isAdding
                    ? product.stockQuantity + qty
                    : (product.stockQuantity - qty).clamp(0, 999999);

                final updated = product.copyWith(
                  stockQuantity: newStock,
                  updatedAt: DateTime.now(),
                );

                await widget.storageService.updateProduct(updated);
                widget.onRefresh();
                await _loadProducts();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAdding
                            ? 'Added $qty units to ${product.name}'
                            : 'Removed $qty units from ${product.name}',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAdjustStock;

  const _InventoryProductCard({
    required this.product,
    this.onTap,
    this.onEdit,
    this.onAdjustStock,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      backgroundColor: product.isOutOfStock
          ? AppTheme.errorPastel.withValues(alpha: 0.1)
          : product.isLowStock
              ? AppTheme.warningPastel.withValues(alpha: 0.1)
              : null,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(product.imageUrl, fit: BoxFit.cover),
                  )
                : const Icon(Icons.shopping_basket_outlined),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.category} • ₹${product.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (product.isOutOfStock)
                      StatusBadge(
                        label: 'Out of Stock',
                        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.redDark : AppTheme.errorPastel,
                      )
                    else if (product.isLowStock)
                      StatusBadge(
                        label: 'Low: ${product.stockQuantity}',
                        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.yellowDark : AppTheme.warningPastel,
                      )
                    else
                      StatusBadge(
                        label: 'Stock: ${product.stockQuantity}',
                        color: AppTheme.successPastel,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.inventory_outlined, size: 20),
                onPressed: onAdjustStock,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

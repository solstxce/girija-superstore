import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';

class ShopTab extends StatelessWidget {
  final List<Product> products;
  final List<Product> filteredProducts;
  final List<String> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  final Function(Product) onProductTap;
  final Function(Product) onAddToCart;

  const ShopTab({
    super.key,
    required this.products,
    required this.filteredProducts,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onProductTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Girija Store'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: ProductSearchDelegate(
                    products: products,
                    onAddToCart: onAddToCart,
                    onProductTap: onProductTap,
                  ),
                );
              },
            ),
          ],
        ),
        // Categories
        SliverToBoxAdapter(
          child: SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: selectedCategory == null,
                    onSelected: (_) => onCategorySelected(null),
                  ),
                ),
                ...categories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: selectedCategory == cat,
                      onSelected: (_) => onCategorySelected(cat),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Products Grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: filteredProducts.isEmpty
              ? const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'No products found',
                    subtitle: 'Try changing filters or search terms',
                  ),
                )
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () => onProductTap(product),
                        onAddToCart: () => onAddToCart(product),
                      );
                    },
                    childCount: filteredProducts.length,
                  ),
                ),
        ),
      ],
    );
  }
}

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> products;
  final Function(Product) onAddToCart;
  final Function(Product)? onProductTap;

  ProductSearchDelegate({
    required this.products,
    required this.onAddToCart,
    this.onProductTap,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = products
        .where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.category.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No products found',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ProductCard(
          product: product,
          onTap: () {
            if (onProductTap != null) {
              close(context, null);
              onProductTap!(product);
            }
          },
          onAddToCart: () {
            onAddToCart(product);
            close(context, product);
          },
        );
      },
    );
  }
}

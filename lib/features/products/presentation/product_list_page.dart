import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_provider.dart';
import '../domain/product_model.dart';
import 'product_detail_page.dart';
import 'add_product_page.dart';

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: productsAsync.when(
        data: (products) {
          final filtered = _searchQuery.isEmpty
              ? products
              : products
                  .where((p) =>
                      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      p.barcode.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(productsProvider.future),
            color: colorScheme.primary,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search by name or barcode...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildProductCard(context, ref, filtered[index], colorScheme),
                      childCount: filtered.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (e, s) => Center(child: Text('Error: $e', style: TextStyle(color: colorScheme.error))),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 20, bottom: 16),
        child: Material(
          elevation: 6,
          shadowColor: colorScheme.primary.withAlpha(120),
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddProductPage()));
              ref.invalidate(productsProvider);
            },
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 6),
                  Text(
                    'New Product',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, WidgetRef ref, ProductModel product, ColorScheme colorScheme) {
    final isLowStock = product.stockQuantity <= 5;
    final stockColor = isLowStock ? colorScheme.error : const Color(0xFF10B981);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withAlpha(40)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)))
            .then((_) => ref.invalidate(productsProvider)),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(product.imageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_rounded, color: colorScheme.primary, size: 32)),
                      )
                    : Icon(Icons.inventory_2_rounded, color: colorScheme.primary, size: 32),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text('\$${product.sellingPrice.toStringAsFixed(2)}', style: TextStyle(color: const Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 14)),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stockColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${product.stockQuantity} in stock', style: TextStyle(color: stockColor, fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _confirmDelete(context, ref, product),
                    child: Icon(Icons.delete_outline_rounded, color: colorScheme.error, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ProductModel product) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Product', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to delete "${product.name}"?', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(productRepositoryProvider).deleteProduct(product.id!);
              ref.invalidate(productsProvider);
            },
            child: Text('Delete', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

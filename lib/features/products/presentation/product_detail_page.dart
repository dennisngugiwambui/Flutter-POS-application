import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../core/theme_context.dart';
import '../../../core/ui_components.dart';
import '../../../core/money_format.dart';
import '../domain/product_model.dart';
import 'edit_product_page.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;
  /// When true, hides cost/margin and staff actions; shows a catalog request CTA.
  final bool clientMode;
  /// Only shop admins may edit products (not manager/cashier).
  final bool canEdit;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.clientMode = false,
    this.canEdit = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = product.stockQuantity <= 5;
    final profit = product.sellingPrice - product.buyingPrice;
    final margin = product.buyingPrice > 0 ? (profit / product.buyingPrice * 100) : 0.0;

    final bg = context.appBg;
    final surface = context.appSurface;
    final text = context.appText;
    final textSub = context.appTextSub;
    final border = context.appBorder;
    final surface2 = context.appSurface2;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Full-width image hero ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x200A2018),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: text, size: 20),
                ),
              ),
            ),
            actions: clientMode || !canEdit
                ? const []
                : [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EditProductPage(product: product)),
                        ).then((_) {
                          if (context.mounted) Navigator.pop(context, true);
                        }),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimary.withAlpha(70),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imageFallback(context),
                        )
                      : _imageFallback(context),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            bg.withAlpha(230),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    child: isLow
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: kError,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: kError.withAlpha(70),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Text(
                                  'Low Stock',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary.withAlpha(70),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Text(
                                  'In Stock',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: text,
                      letterSpacing: -0.6,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: border, width: 0.9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_rounded, color: textSub, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              product.barcode.isEmpty ? 'No barcode' : product.barcode,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (clientMode)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimary.withAlpha(18), kPrimary.withAlpha(6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kPrimary.withAlpha(45), width: 0.9),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price',
                            style: TextStyle(fontSize: 11, color: textSub, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatKes(product.sellingPrice),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: kPrimary,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimary.withAlpha(18), kPrimary.withAlpha(6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kPrimary.withAlpha(45), width: 0.9),
                      ),
                      child: Row(
                        children: [
                          _priceCol(
                            context,
                            label: 'Selling Price',
                            value: formatKes(product.sellingPrice),
                            color: kPrimary,
                            large: true,
                          ),
                          Container(
                            width: 0.9,
                            height: 44,
                            color: kPrimary.withAlpha(30),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          _priceCol(
                            context,
                            label: 'Buying Price',
                            value: formatKes(product.buyingPrice),
                            color: textSub,
                            large: false,
                          ),
                          Container(
                            width: 0.9,
                            height: 44,
                            color: kPrimary.withAlpha(30),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          _priceCol(
                            context,
                            label: 'Profit',
                            value: formatKes(profit),
                            color: profit >= 0 ? kPrimary : kError,
                            large: false,
                          ),
                        ],
                      ),
                    ),
                  if (!clientMode) const SizedBox(height: 14),
                  if (!clientMode)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: margin >= 20 ? kPrimary.withAlpha(15) : kWarning.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: margin >= 20 ? kPrimary.withAlpha(45) : kWarning.withAlpha(45),
                              width: 0.9,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.show_chart_rounded,
                                size: 14,
                                color: margin >= 20 ? kPrimary : kWarning,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Margin: ${margin.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: margin >= 20 ? kPrimary : kWarning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 22),
                  Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.qr_code_2_rounded,
                          label: 'Barcode',
                          value: product.barcode.isEmpty ? '—' : product.barcode,
                          iconColor: kPrimary,
                        ),
                        Divider(height: 1, color: border.withAlpha(160), indent: 54),
                        if (!clientMode) ...[
                          _DetailRow(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Buying Price',
                            value: formatKes(product.buyingPrice),
                            iconColor: textSub,
                          ),
                          Divider(height: 1, color: border.withAlpha(160), indent: 54),
                        ],
                        _DetailRow(
                          icon: Icons.sell_rounded,
                          label: 'Selling Price',
                          value: formatKes(product.sellingPrice),
                          iconColor: kPrimary,
                          valueColor: kPrimary,
                        ),
                        Divider(height: 1, color: border.withAlpha(160), indent: 54),
                        _DetailRow(
                          icon: Icons.inventory_2_rounded,
                          label: 'Stock Quantity',
                          value: '${product.stockQuantity} units',
                          iconColor: isLow ? kError : kPrimary,
                          valueColor: isLow ? kError : null,
                          trailing: isLow
                              ? null
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: kPrimary.withAlpha(15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'In stock',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: kPrimary,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: clientMode
                        ? ElevatedButton.icon(
                            onPressed: () => _showClientRequestDialog(context, product),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            label: const Text(
                              'Request this product',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          )
                        : canEdit
                            ? ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => EditProductPage(product: product)),
                                ).then((_) {
                                  if (context.mounted) Navigator.pop(context, true);
                                }),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                                label: const Text(
                                  'Edit Product',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  Widget _priceCol(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required bool large,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: context.appTextSub, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 16 : 13,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  static void _showClientRequestDialog(BuildContext context, ProductModel product) {
    final note = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send a request',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Quantity, timing, or other notes (optional)',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          note.text.trim().isEmpty
                              ? 'Request noted for "${product.name}". The shop will follow up with you.'
                              : 'Request sent: ${note.text.trim()}',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: kPrimary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(note.dispose);
  }

  static Widget _imageFallback(BuildContext context) {
    return Container(
      color: context.appSurface2,
      child: Center(
        child: Icon(Icons.inventory_2_outlined, size: 64, color: context.appTextMuted),
      ),
    );
  }
}

// ── Detail row ─────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;
  final Widget? trailing;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (iconColor ?? kPrimary).withAlpha(18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? kPrimary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: context.appTextSub, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? context.appText,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/app_theme.dart';
import '../../../core/theme_context.dart';
import '../../dashboard/presentation/main_shell.dart';
import '../../../core/money_format.dart';
import '../../../core/ui_components.dart';
import '../../products/domain/product_model.dart';
import '../../products/presentation/product_provider.dart';
import '../domain/cart_item_model.dart';
import '../../settings/presentation/settings_provider.dart';
import 'cart_provider.dart';
import 'checkout_payment_page.dart';
import 'receipt_page.dart';

class SalePage extends ConsumerStatefulWidget {
  const SalePage({super.key});

  @override
  ConsumerState<SalePage> createState() => _SalePageState();
}

class _SalePageState extends ConsumerState<SalePage> with WidgetsBindingObserver {
  final _searchCtrl = TextEditingController();
  final _scannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
    ],
  );

  String _query = '';
  bool _scannerOpen = false;
  bool _hasScanned = false;
  static const _scanCooldownMs = 220;
  String? _lastBarcode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      unawaited(_stopScannerIfOpen());
    }
  }

  /// Fully releases the camera when leaving POS tab, app switcher, or lock screen.
  Future<void> _stopScannerIfOpen() async {
    if (!_scannerOpen) return;
    await _scannerCtrl.stop();
    if (mounted) setState(() => _scannerOpen = false);
  }

  Future<void> _ensureCamera() async {
    var s = await Permission.camera.status;
    if (!s.isGranted) await Permission.camera.request();
  }

  List<ProductModel> _filtered(List<ProductModel> all) {
    if (_query.isEmpty) return [];
    final q = _query;
    return all
        .where((p) => p.name.toLowerCase().contains(q) || p.barcode.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _openCheckout(CartState cartState) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPaymentPage(cartState: cartState),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      final success = result['success'] as bool? ?? false;
      final message = result['message'] as String? ?? (success ? 'Done.' : 'Failed.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(success ? Icons.check_circle_rounded : Icons.error_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          backgroundColor: success ? kPrimary : kError,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        ),
      );
      if (success) {
        ref.read(cartProvider.notifier).clearCart();
        final settings = await ref.read(settingsProvider.future);
        if (!mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.black54,
          barrierColor: Colors.black54,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            return SafeArea(
              top: false,
              child: FractionallySizedBox(
                heightFactor: 0.9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: ReceiptPage(
                    items: cartState.items,
                    totalAmount: cartState.totalAmount,
                    initialShopSettings: settings,
                  ),
                ),
              ),
            );
          },
        );
      }
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;
    final codes = capture.barcodes;
    if (codes.isEmpty) return;
    final val = codes.first.rawValue?.trim();
    if (val == null || val.isEmpty) return;
    if (_lastBarcode == val) return;
    _lastBarcode = val;
    _hasScanned = true;
    HapticFeedback.mediumImpact();
    _searchCtrl.text = val;
    setState(() {
      _query = val.toLowerCase();
      _scannerOpen = false;
    });
    _scannerCtrl.stop();
    unawaited(_resolveScannedBarcode(val));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _hasScanned = false;
    });
    Future.delayed(const Duration(milliseconds: _scanCooldownMs), () {
      _lastBarcode = null;
    });
  }

  /// Looks up product by barcode; adds to cart or tells the user to create the product first.
  Future<void> _resolveScannedBarcode(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    final q = trimmed.toLowerCase();
    try {
      final list = await ref.read(productsProvider.future);
      ProductModel? found;
      for (final p in list) {
        if (p.barcode.trim().toLowerCase() == q) {
          found = p;
          break;
        }
      }
      found ??= await ref.read(productRepositoryProvider).getProductByBarcode(trimmed);
      if (!mounted) return;
      if (found != null) {
        await _addProduct(found);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No product with barcode "$trimmed". Add it in Products first, then scan again.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: kError,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not look up barcode: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kError,
        ),
      );
    }
  }

  Future<void> _addProduct(ProductModel p) async {
    await ref.read(cartProvider.notifier).addProductByBarcode(p.barcode);
    if (!mounted) return;
    _searchCtrl.clear();
    setState(() => _query = '');
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final productsAsync = ref.watch(productsProvider);
    final lineQty = cartState.items.fold<int>(0, (s, i) => s + i.quantity);

    ref.listen<int>(mainShellTabProvider, (prev, next) {
      if (next != 2) unawaited(_stopScannerIfOpen());
    });

    return Scaffold(
      backgroundColor: context.appBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  TopIconBtn(
                    icon: Icons.menu_rounded,
                    onTap: () => MainShell.shellScaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'New Sale',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: context.appText,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  TopIconBtn(
                    icon: _scannerOpen ? Icons.close_rounded : Icons.qr_code_scanner_rounded,
                    onTap: () async {
                      if (!_scannerOpen) {
                        await _ensureCamera();
                        if (!mounted) return;
                        await _scannerCtrl.start();
                        if (mounted) setState(() => _scannerOpen = true);
                      } else {
                        await _stopScannerIfOpen();
                      }
                    },
                    bg: _scannerOpen ? kPrimary.withAlpha(15) : context.appSurface,
                    iconColor: _scannerOpen ? kPrimary : context.appText,
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              crossFadeState: _scannerOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 180,
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: _scannerCtrl,
                          onDetect: _onBarcodeDetected,
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: ListenableBuilder(
                            listenable: _scannerCtrl,
                            builder: (context, _) {
                              final torch = _scannerCtrl.value.torchState;
                              if (torch == TorchState.unavailable) {
                                return const SizedBox.shrink();
                              }
                              final on = torch == TorchState.on || torch == TorchState.auto;
                              return Material(
                                color: Colors.black.withAlpha(120),
                                borderRadius: BorderRadius.circular(14),
                                child: IconButton(
                                  tooltip: on ? 'Turn flash off' : 'Turn flash on',
                                  onPressed: () async => _scannerCtrl.toggleTorch(),
                                  icon: Icon(
                                    on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                    color: on ? const Color(0xFFFFB347) : Colors.white,
                                    size: 22,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 200,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: kPrimary, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(140),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 6,
                                    height: 6,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Align barcode within frame',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: AppSearchBar(
                hint: 'Search by name or barcode...',
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
                suffix: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(Icons.close_rounded, color: context.appTextMuted, size: 18),
                        ),
                      )
                    : null,
              ),
            ),
            if (_query.isNotEmpty)
              productsAsync.when(
                data: (products) {
                  final results = _filtered(products);
                  if (results.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.appSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.appBorder, width: 0.9),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_off_rounded, color: context.appTextMuted, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'No products found',
                              style: TextStyle(color: context.appTextSub, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Container(
                    margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.appBorder, width: 0.9),
                      boxShadow: [
                        BoxShadow(color: Theme.of(context).colorScheme.shadow.withAlpha(28), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final p = results[i];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _addProduct(p),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: p.imageUrl.isNotEmpty
                                          ? Image.network(
                                              p.imageUrl,
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => _productIconBox(),
                                            )
                                          : _productIconBox(),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: context.appText,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                formatKes(p.sellingPrice),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: kPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: p.stockQuantity <= 5 ? kError.withAlpha(15) : kPrimary.withAlpha(12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${p.stockQuantity} left',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: p.stockQuantity <= 5 ? kError : kPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: kPrimary.withAlpha(15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.add_rounded, color: kPrimary, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Text(
                    'Cart',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.appText),
                  ),
                  if (cartState.items.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kPrimary.withAlpha(15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$lineQty item${lineQty != 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: cartState.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: context.appSurface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: context.appBorder, width: 0.9),
                            ),
                            child: Icon(Icons.shopping_cart_outlined, color: context.appTextMuted, size: 32),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Cart is empty',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.appText),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Search or scan a product to add it',
                            style: TextStyle(fontSize: 12, color: context.appTextSub),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: cartState.items.length,
                      itemBuilder: (_, i) {
                        final item = cartState.items[i];
                        return _CartRow(
                          item: item,
                          onAdd: () => ref.read(cartProvider.notifier).updateQuantity(item.product.barcode, item.quantity + 1),
                          onRemove: () => ref.read(cartProvider.notifier).updateQuantity(item.product.barcode, item.quantity - 1),
                          onRemoveLine: () => ref.read(cartProvider.notifier).removeItem(item.product.barcode),
                        );
                      },
                    ),
            ),
            _CheckoutBar(
              total: cartState.totalAmount,
              itemCount: lineQty,
              onCheckout: () {
                if (cartState.items.isEmpty) return;
                _openCheckout(cartState);
              },
              onClear: () => ref.read(cartProvider.notifier).clearCart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productIconBox() => Builder(
        builder: (context) => Container(
          width: 44,
          height: 44,
          color: context.appSurface2,
          child: Icon(Icons.inventory_2_outlined, size: 20, color: context.appTextMuted),
        ),
      );
}

class _CartRow extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onRemoveLine;

  const _CartRow({
    required this.item,
    required this.onAdd,
    required this.onRemove,
    required this.onRemoveLine,
  });

  @override
  Widget build(BuildContext context) {
    final keyVal = item.product.barcode;
    return Slidable(
      key: ValueKey(keyVal),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.18,
        children: [
          SlidableAction(
            onPressed: (_) => onRemoveLine(),
            backgroundColor: kError,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appBorder, width: 0.9),
          boxShadow: [
            BoxShadow(color: Theme.of(context).colorScheme.shadow.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.product.imageUrl.isNotEmpty
                  ? Image.network(
                      item.product.imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 48,
                        height: 48,
                        color: context.appSurface2,
                        child: Icon(Icons.inventory_2_outlined, size: 22, color: context.appTextMuted),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: context.appSurface2,
                      child: Icon(Icons.inventory_2_outlined, size: 22, color: context.appTextMuted),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.appText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatKes(item.product.sellingPrice),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimary),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _stepBtn(icon: Icons.remove_rounded, onTap: onRemove, color: kError),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: context.appText),
                  ),
                ),
                _stepBtn(icon: Icons.add_rounded, onTap: onAdd, color: kPrimary),
              ],
            ),
            const SizedBox(width: 10),
            Text(
              formatKes(item.totalPrice),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: context.appText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn({required IconData icon, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final double total;
  final int itemCount;
  final VoidCallback onCheckout;
  final VoidCallback onClear;

  const _CheckoutBar({
    required this.total,
    required this.itemCount,
    required this.onCheckout,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder, width: 0.9)),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.shadow.withAlpha(24), blurRadius: 18, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemCount item${itemCount != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 11, color: context.appTextSub, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  formatKes(total),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: context.appText,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (itemCount > 0) ...[
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kError.withAlpha(12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kError.withAlpha(40), width: 0.9),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: kError, size: 20),
              ),
            ),
            const SizedBox(width: 10),
          ],
          GestureDetector(
            onTap: onCheckout,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              decoration: BoxDecoration(
                gradient: itemCount > 0
                    ? const LinearGradient(
                        colors: [Color(0xFF1B8B5A), Color(0xFF26B573)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: itemCount > 0 ? null : context.appSurface2,
                borderRadius: BorderRadius.circular(16),
                boxShadow: itemCount > 0
                    ? [BoxShadow(color: kPrimary.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.payment_rounded,
                    color: itemCount > 0 ? Colors.white : context.appTextMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    itemCount > 0 ? 'Checkout' : 'Add items',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: itemCount > 0 ? Colors.white : context.appTextMuted,
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

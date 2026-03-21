import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shop/components/cart_button.dart';
import 'cart_provider.dart';
import 'receipt_page.dart';
import 'checkout_payment_page.dart';
import '../../products/domain/product_model.dart';
import '../../products/presentation/product_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../../core/money_format.dart';

class SalePage extends ConsumerStatefulWidget {
  const SalePage({super.key});

  @override
  ConsumerState<SalePage> createState() => _SalePageState();
}

class _SalePageState extends ConsumerState<SalePage> with TickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.qrCode,
    ],
  );
  final TextEditingController _barcodeInputController = TextEditingController();
  bool _scannerExpanded = false;
  bool _cameraDenied = false;
  static const double _scannerMaxHeight = 160;
  Timer? _barcodeDebounce;
  static const _barcodeDebounceDuration = Duration(milliseconds: 400);
  String? _lastScannedBarcode;
  static const _scanCooldownMs = 220;

  // Live search results for type-to-search
  List<ProductModel> _searchResults = [];

  late AnimationController _scannerAnim;
  late Animation<double> _scannerHeight;
  late AnimationController _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _scannerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scannerHeight = Tween<double>(begin: 0, end: _scannerMaxHeight).animate(
      CurvedAnimation(parent: _scannerAnim, curve: Curves.easeInOut),
    );
    _scannerAnim.forward();
    _scanLineAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _requestCameraPermission();
    _barcodeInputController.addListener(_onBarcodeInputChanged);
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!mounted) return;
      setState(() => _cameraDenied = status.isDenied || status.isPermanentlyDenied);
    }
  }

  void _onBarcodeInputChanged() {
    _barcodeDebounce?.cancel();
    final query = _barcodeInputController.text.trim();
    if (query.isEmpty) {
      if (mounted) {
        setState(() => _searchResults = []);
      }
      return;
    }
    _barcodeDebounce = Timer(_barcodeDebounceDuration, () async {
      if (!mounted || _barcodeInputController.text.trim() != query) return;
      final results = await ref.read(productRepositoryProvider).searchProducts(query);
      if (!mounted) return;
      setState(() => _searchResults = results);
    });
  }

  void _showScanNotification(String barcode, ProductModel? product) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.done_all_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                product != null
                    ? 'Scanned: $barcode • Added: ${product.name}'
                    : 'Scanned: $barcode • Product not found',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: product != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      ),
    );
  }

  @override
  void dispose() {
    _barcodeDebounce?.cancel();
    _barcodeInputController.removeListener(_onBarcodeInputChanged);
    _barcodeInputController.dispose();
    _scannerController.dispose();
    _scannerAnim.dispose();
    _scanLineAnim.dispose();
    super.dispose();
  }

  void _toggleScanner() {
    setState(() => _scannerExpanded = !_scannerExpanded);
    if (_scannerExpanded) {
      _scannerAnim.reverse();
    } else {
      _scannerAnim.forward();
    }
  }

  Widget _buildCornerAccents(Color color) {
    const size = 24.0;
    const stroke = 3.0;
    return Center(
      child: SizedBox(
        width: 240,
        height: 120,
        child: Stack(
          children: [
            Positioned(top: 0, left: 0, child: _cornerL(color, size, stroke)),
            Positioned(top: 0, right: 0, child: _cornerR(color, size, stroke)),
            Positioned(bottom: 0, left: 0, child: Transform.rotate(angle: -0.5 * 3.14159, child: _cornerL(color, size, stroke))),
            Positioned(bottom: 0, right: 0, child: Transform.rotate(angle: 0.5 * 3.14159, child: _cornerR(color, size, stroke))),
          ],
        ),
      ),
    );
  }

  Widget _cornerL(Color color, double size, double stroke) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(color: color, stroke: stroke, isLeft: true),
      ),
    );
  }

  Widget _cornerR(Color color, double size, double stroke) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(color: color, stroke: stroke, isLeft: false),
      ),
    );
  }

  Future<void> _manualEntry() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1F36),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Barcode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Scan or type barcode number...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withAlpha(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                ),
                prefixIcon: const Icon(Icons.qr_code_rounded, color: Color(0xFF6366F1)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('ADD TO CART', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(cartProvider.notifier).addProductByBarcode(result);
    }
  }

  Future<void> _openCheckout(CartState cartState) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPaymentPage(cartState: cartState),
      ),
    );
    if (!mounted) return;
    // Only clear cart after a successful sale. Failed checkout or pressing back must keep items.
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
          backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
          backgroundColor: Colors.black.withOpacity(0.4),
          barrierColor: Colors.black.withOpacity(0.4),
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

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurf = colorScheme.onSurface;
    final surfLow = colorScheme.surfaceContainerHighest;
    final primary = colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('New Sale', style: TextStyle(fontWeight: FontWeight.w900, color: onSurf)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: onSurf.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit_outlined, color: onSurf.withAlpha(200), size: 18),
            ),
            onPressed: _manualEntry,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: onSurf.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _scannerExpanded ? Icons.camera_alt_rounded : Icons.camera_alt_outlined,
                color: _scannerExpanded ? primary : onSurf.withAlpha(200),
                size: 18,
              ),
            ),
            onPressed: _toggleScanner,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: onSurf.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.flash_on_rounded, color: onSurf.withAlpha(200), size: 18),
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Scanner (collapsed by default; tap camera icon to expand)
          AnimatedBuilder(
            animation: _scannerAnim,
            builder: (context, child) => SizedBox(
              height: _scannerMaxHeight - _scannerHeight.value,
              child: child,
            ),
            child: _scannerExpanded
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withAlpha(80),
                          blurRadius: 24,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: colorScheme.shadow.withAlpha(100),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: primary.withAlpha(120), width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: (capture) async {
                            final barcodes = capture.barcodes;
                            if (barcodes.isEmpty) return;
                            final code = barcodes.first;
                            final barcode = (code.rawValue ?? code.displayValue ?? '').trim();
                            if (barcode.isEmpty) return;
                            if (_lastScannedBarcode == barcode) return;
                            _lastScannedBarcode = barcode;
                            HapticFeedback.mediumImpact();
                            Future.delayed(const Duration(milliseconds: _scanCooldownMs), () {
                              if (mounted) setState(() => _lastScannedBarcode = null);
                            });
                            final product = await ref.read(cartProvider.notifier).addProductByBarcode(barcode);
                            if (!mounted) return;
                            _showScanNotification(barcode, product);
                          },
                        ),
                        // Viewfinder frame
                        Center(
                          child: Container(
                            width: 240,
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: primary, width: 2.5),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withAlpha(100),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedBuilder(
                                  animation: _scanLineAnim,
                                  builder: (context, _) => Positioned(
                                    left: 0,
                                    right: 0,
                                    top: (_scanLineAnim.value * 120).clamp(0.0, 120.0),
                                    child: Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            primary.withAlpha(220),
                                            primary.withAlpha(255),
                                            primary.withAlpha(220),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primary.withAlpha(150),
                                            blurRadius: 8,
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
                        _buildCornerAccents(primary),
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Align barcode within frame',
                                style: TextStyle(color: onSurf.withAlpha(200), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          // Barcode type-to-search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _barcodeInputController,
              style: TextStyle(color: onSurf, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search by barcode or name...',
                hintStyle: TextStyle(color: onSurf.withAlpha(120)),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Icon(Icons.qr_code_scanner_rounded, color: primary, size: 22),
                ),
                filled: true,
                fillColor: surfLow.withAlpha(60),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primary.withAlpha(80)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: onSurf.withAlpha(40)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (value) async {
                final b = value.trim();
                if (b.isEmpty) return;
                final product = await ref.read(cartProvider.notifier).addProductByBarcode(b);
                if (!mounted) return;
                _barcodeInputController.clear();
                setState(() => _searchResults = []);
                _showScanNotification(b, product);
              },
            ),
          ),
          if (_searchResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 240),
                decoration: BoxDecoration(
                  color: surfLow.withAlpha(80),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withAlpha(80)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final p = _searchResults[index];
                    return ListTile(
                      leading: Icon(Icons.inventory_2_rounded, color: primary),
                      title: Text(p.name, style: TextStyle(color: onSurf)),
                      subtitle: Text(
                        p.barcode,
                        style: TextStyle(color: onSurf.withAlpha(160), fontSize: 12),
                      ),
                      trailing: Text(
                        formatKes(p.sellingPrice),
                        style: TextStyle(color: colorScheme.tertiary, fontWeight: FontWeight.w700),
                      ),
                      onTap: () async {
                        final product = await ref.read(cartProvider.notifier).addProductByBarcode(p.barcode);
                        if (!mounted) return;
                        _barcodeInputController.clear();
                        setState(() => _searchResults = []);
                        _showScanNotification(p.barcode, product);
                      },
                    );
                  },
                ),
              ),
            ),
          if (_cameraDenied)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange.shade300),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Camera denied. Enable in device settings to scan.',
                      style: TextStyle(color: Colors.orange.shade300, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          // Scanned items header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: surfLow.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    cartState.items.isEmpty
                        ? 'Scanned items'
                        : 'Scanned items (${cartState.items.fold<int>(0, (sum, i) => sum + i.quantity)} total)',
                    style: TextStyle(color: onSurf.withAlpha(200), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                if (cartState.items.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                    icon: Icon(Icons.delete_sweep_rounded, size: 18, color: colorScheme.error),
                    label: Text('Clear cart', style: TextStyle(color: colorScheme.error, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          // Cart List
          Expanded(
            child: cartState.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: surfLow.withAlpha(80),
                            shape: BoxShape.circle,
                            border: Border.all(color: onSurf.withAlpha(30)),
                          ),
                          child: Icon(Icons.shopping_cart_outlined, size: 48, color: onSurf.withAlpha(100)),
                        ),
                        const SizedBox(height: 20),
                        Text('Cart is empty', style: TextStyle(color: onSurf.withAlpha(150), fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          'Scan a barcode or type above to add items.\nSwipe item left to delete.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: onSurf.withAlpha(140), fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  )
                : ConstrainedBox(
                    constraints: BoxConstraints(minHeight: _scannerExpanded ? 160 : 0),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: cartState.items.length,
                      itemBuilder: (context, index) {
                        final item = cartState.items[index];
                        return _buildCartItem(ref, item);
                      },
                    ),
                  ),
          ),
          // Checkout footer
          _buildCheckoutFooter(context, cartState),
        ],
      ),
    );
  }

  Widget _buildCartItem(WidgetRef ref, dynamic item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(item.product.barcode),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.14,
          children: [
            SlidableAction(
              onPressed: (_) => ref.read(cartProvider.notifier).removeItem(item.product.barcode),
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              icon: Icons.delete_outline_rounded,
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outline.withAlpha(40)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: item.product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(item.product.imageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_outlined, color: colorScheme.primary, size: 22)),
                      )
                    : Icon(Icons.inventory_2_outlined, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.name, style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                      '${formatKes(item.product.sellingPrice)} each',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatKes(item.totalPrice), style: TextStyle(color: colorScheme.tertiary, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(80),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _QuantityButton(
                          icon: Icons.remove_rounded,
                          onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.barcode, item.quantity - 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${item.quantity}', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                        _QuantityButton(
                          icon: Icons.add_rounded,
                          onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.barcode, item.quantity + 1),
                        ),
                      ],
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

  Widget _buildCheckoutFooter(BuildContext context, CartState cartState) {
    final colorScheme = Theme.of(context).colorScheme;
    final lineQty = cartState.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final checkoutSubTitle = cartState.items.isEmpty
        ? 'Tap to pay'
        : (lineQty == 1 ? '1 item • Tap to pay' : '$lineQty items • Tap to pay');
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(color: colorScheme.primary.withAlpha(30), blurRadius: 20, offset: const Offset(0, -4)),
          BoxShadow(color: colorScheme.shadow.withAlpha(80), blurRadius: 24, offset: const Offset(0, -6)),
        ],
        border: Border(top: BorderSide(color: colorScheme.outline.withAlpha(60))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                    Text(
                      formatKes(cartState.totalAmount),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Items', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                    Text(
                      '${cartState.items.fold<int>(0, (sum, i) => sum + i.quantity)}',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: cartState.items.isEmpty ? 0.45 : 1,
              child: CartButton(
                price: cartState.totalAmount,
                title: cartState.items.isEmpty ? 'Add items' : 'CHECKOUT',
                subTitle: checkoutSubTitle,
                press: () {
                  if (cartState.items.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scan or search to add items first.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  _openCheckout(cartState);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(120),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colorScheme.onSurface, size: 16),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double stroke;
  final bool isLeft;

  _CornerPainter({required this.color, required this.stroke, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    if (isLeft) {
      canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
      canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
    } else {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(0, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

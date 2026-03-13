import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cart_provider.dart';
import '../data/mpesa_repository.dart';
import '../../products/presentation/product_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../../dashboard_provider.dart';

enum PaymentMethod { cash, stk }

final mpesaRepositoryProvider = Provider<MpesaRepository>((ref) => MpesaRepository());

class CheckoutPaymentPage extends ConsumerStatefulWidget {
  final CartState cartState;

  const CheckoutPaymentPage({super.key, required this.cartState});

  @override
  ConsumerState<CheckoutPaymentPage> createState() => _CheckoutPaymentPageState();
}

class _CheckoutPaymentPageState extends ConsumerState<CheckoutPaymentPage> {
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final TextEditingController _amountReceivedController = TextEditingController();
  final TextEditingController _mpesaDigitsController = TextEditingController();
  static const String _mpesaPrefix = '+254';
  bool _isSubmitting = false;
  String? _changeError;

  @override
  void dispose() {
    _amountReceivedController.dispose();
    _mpesaDigitsController.dispose();
    super.dispose();
  }

  double? get _amountReceived {
    final t = _amountReceivedController.text.trim().replaceAll(RegExp(r'[^\d.]'), '');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  double get _change {
    final received = _amountReceived;
    if (received == null) return 0;
    final total = widget.cartState.totalAmount;
    return (received - total).clamp(0.0, double.infinity);
  }

  String get _fullMpesaPhone {
    final digits = _mpesaDigitsController.text.trim().replaceAll(RegExp(r'\D'), '');
    return '$_mpesaPrefix$digits';
  }

  bool get _isMpesaValid {
    final digits = _mpesaDigitsController.text.trim().replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9;
  }

  Future<void> _completeSaleAndPop({required bool success, required String message}) async {
    if (!mounted) return;
    Navigator.pop(context, {'success': success, 'message': message});
  }

  Future<void> _submitCash() async {
    final received = _amountReceived;
    final total = widget.cartState.totalAmount;
    if (received == null || received < total) {
      setState(() => _changeError = 'Amount received must be at least \$${total.toStringAsFixed(2)}');
      return;
    }
    setState(() { _isSubmitting = true; _changeError = null; });
    try {
      await ref.read(dashboardStatsRepositoryProvider).recordSale(widget.cartState.totalAmount, widget.cartState.items);
      ref.invalidate(dashboardStatsProvider);
      final productRepo = ref.read(productRepositoryProvider);
      for (final item in widget.cartState.items) {
        final product = item.product;
        if (product.id == null) continue;
        final newStock = (product.stockQuantity - item.quantity).clamp(0, 1 << 31);
        await productRepo.updateStock(product.id!, newStock);
      }
      ref.invalidate(productsProvider);
      if (!mounted) return;
      final change = _change;
      await _completeSaleAndPop(
        success: true,
        message: 'Success. Change: \$${change.toStringAsFixed(2)}',
      );
    } catch (e) {
      if (!mounted) return;
      await _completeSaleAndPop(success: false, message: 'Failed. $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitStk() async {
    if (!_isMpesaValid) {
      setState(() => _changeError = 'Enter valid phone (9 digits after +254)');
      return;
    }
    setState(() { _isSubmitting = true; _changeError = null; });
    final phone = _fullMpesaPhone;
    try {
      final settings = await ref.read(settingsProvider.future);
      if (!settings.isMpesaConfigured) {
        if (!mounted) return;
        setState(() => _changeError = 'Configure M-Pesa in Shop Settings (Consumer Key, Secret, Passkey, Till, Callback URL).');
        setState(() => _isSubmitting = false);
        return;
      }

      final repo = ref.read(mpesaRepositoryProvider);
      final total = widget.cartState.totalAmount;
      final result = await repo.initiateStkPush(
        amount: total,
        phone: phone,
        reference: 'POS${DateTime.now().millisecondsSinceEpoch % 100000}',
      );

      if (!mounted) return;
      if (!result.success) {
        await _completeSaleAndPop(success: false, message: result.message);
        setState(() => _isSubmitting = false);
        return;
      }

      await ref.read(dashboardStatsRepositoryProvider).recordSale(total, widget.cartState.items);
      ref.invalidate(dashboardStatsProvider);
      final productRepo = ref.read(productRepositoryProvider);
      for (final item in widget.cartState.items) {
        final product = item.product;
        if (product.id == null) continue;
        final newStock = (product.stockQuantity - item.quantity).clamp(0, 1 << 31);
        await productRepo.updateStock(product.id!, newStock);
      }
      ref.invalidate(productsProvider);
      if (!mounted) return;
      await _completeSaleAndPop(success: true, message: 'Payment received. STK completed for $phone');
    } catch (e) {
      if (!mounted) return;
      await _completeSaleAndPop(success: false, message: 'Failed. $e');
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = widget.cartState.totalAmount;
    final itemCount = widget.cartState.items.fold<int>(0, (sum, i) => sum + i.quantity);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Checkout', style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withAlpha(80)),
              ),
              child: Column(
                children: [
                  Text('Total', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text('$itemCount items', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Payment method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _methodChip(PaymentMethod.cash, 'Cash', Icons.payments_rounded, colorScheme),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _methodChip(PaymentMethod.stk, 'STK Push', Icons.phone_android_rounded, colorScheme),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_paymentMethod == PaymentMethod.cash) ..._buildCashSection(colorScheme),
            if (_paymentMethod == PaymentMethod.stk) ..._buildStkSection(colorScheme),
            if (_changeError != null) ...[
              const SizedBox(height: 8),
              Text(_changeError!, style: TextStyle(color: colorScheme.error, fontSize: 13)),
            ],
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (_paymentMethod == PaymentMethod.cash) {
                          await _submitCash();
                        } else {
                          await _submitStk();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                    : Text(
                        _paymentMethod == PaymentMethod.cash ? 'Complete sale' : 'Send STK push',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodChip(PaymentMethod method, String label, IconData icon, ColorScheme colorScheme) {
    final selected = _paymentMethod == method;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() { _paymentMethod = method; _changeError = null; }),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outline.withAlpha(80),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCashSection(ColorScheme colorScheme) {
    return [
      Text('Amount received', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      TextField(
        controller: _amountReceivedController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        decoration: InputDecoration(
          hintText: '0.00',
          prefixText: '\$ ',
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      if (_amountReceived != null && _amountReceived! >= widget.cartState.totalAmount) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer.withAlpha(80),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Change to give', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
              Text('\$${_change.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.tertiary)),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildStkSection(ColorScheme colorScheme) {
    return [
      Text('Customer phone (M-Pesa)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.horizontal(left: Radius.zero, right: const Radius.circular(12)),
              border: Border.all(color: colorScheme.outline.withAlpha(120)),
            ),
            child: Text(_mpesaPrefix, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          ),
          Expanded(
            child: TextField(
              controller: _mpesaDigitsController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              maxLength: 9,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '7XXXXXXXX',
                counterText: '',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.horizontal(left: Radius.zero, right: const Radius.circular(12)),
                  borderSide: BorderSide(color: colorScheme.outline.withAlpha(120)),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text('Enter last 9 digits. STK push will be sent to $_mpesaPrefix...', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
    ];
  }
}

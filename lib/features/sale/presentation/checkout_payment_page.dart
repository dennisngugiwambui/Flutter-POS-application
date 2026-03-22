import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cart_provider.dart';
import '../../mpesa/mpesa_service.dart';
import '../../products/presentation/product_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../../dashboard_provider.dart';
import '../../../core/app_theme.dart';
import '../../../core/money_format.dart';

enum PaymentMethod { cash, stk }

class CheckoutPaymentPage extends ConsumerStatefulWidget {
  final CartState cartState;

  const CheckoutPaymentPage({super.key, required this.cartState});

  @override
  ConsumerState<CheckoutPaymentPage> createState() => _CheckoutPaymentPageState();
}

class _CheckoutPaymentPageState extends ConsumerState<CheckoutPaymentPage>
    with SingleTickerProviderStateMixin {
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final TextEditingController _amountReceivedController = TextEditingController();
  final TextEditingController _mpesaDigitsController = TextEditingController();
  static const String _mpesaPrefix = '+254';
  bool _isSubmitting = false;
  String? _changeError;
  String? _stkStatus;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _amountReceivedController.dispose();
    _mpesaDigitsController.dispose();
    _animCtrl.dispose();
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
      setState(() => _changeError = 'Amount received must be at least ${formatKes(total)}');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _changeError = null;
    });
    try {
      await ref.read(dashboardStatsRepositoryProvider).recordSale(widget.cartState.totalAmount, widget.cartState.items);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(productsProvider);
      if (!mounted) return;
      final change = _change;
      await _completeSaleAndPop(
        success: true,
        message: 'Success. Change: ${formatKes(change)}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _changeError = 'Could not complete sale: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitStk() async {
    if (!_isMpesaValid) {
      setState(() => _changeError = 'Enter valid phone (9 digits after +254)');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _changeError = null;
      _stkStatus = null;
    });
    final phone = _fullMpesaPhone;
    try {
      final settings = await ref.read(settingsProvider.future);
      final total = widget.cartState.totalAmount;
      final mpesa = ref.read(mpesaServiceProvider);
      final result = await mpesa.pay(
        phone: phone,
        amount: total,
        settings: settings,
        accountReference: 'POS${DateTime.now().millisecondsSinceEpoch % 100000}',
        onStatusUpdate: (msg) {
          if (!mounted) return;
          setState(() => _stkStatus = msg);
        },
      );

      if (!mounted) return;
      if (!result.success) {
        setState(() {
          _changeError = result.errorMessage ?? result.message;
          _stkStatus = null;
          _isSubmitting = false;
        });
        return;
      }

      await ref.read(dashboardStatsRepositoryProvider).recordSale(
            total,
            widget.cartState.items,
            paymentMethod: 'mpesa',
          );
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(productsProvider);
      if (!mounted) return;
      final paidMsg = result.receiptNumber != null && result.receiptNumber!.isNotEmpty
          ? 'Paid. M-Pesa receipt: ${result.receiptNumber}'
          : 'Payment received. STK completed for $phone';
      await _completeSaleAndPop(success: true, message: paidMsg);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _changeError = 'M-Pesa request failed: $e';
        _stkStatus = null;
      });
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  List<double> _quickAmounts() {
    final total = widget.cartState.totalAmount;
    final base = (total / 100).ceil() * 100.0;
    final amounts = <double>{total, base, base + 100, base + 200, base + 500};
    return amounts.where((a) => a >= total).take(5).toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = widget.cartState.totalAmount;
    final itemCount = widget.cartState.items.fold<int>(0, (sum, i) => sum + i.quantity);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B8B5A), Color(0xFF26B573)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withAlpha(70),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(15),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$itemCount item${itemCount != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatKes(total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total due',
                              style: TextStyle(
                                color: Colors.white.withAlpha(170),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ...widget.cartState.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.quantity}× ${item.product.name}',
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(210),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      formatKes(item.totalPrice),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
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
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentMethodCard(
                            icon: Icons.payments_rounded,
                            label: 'Cash',
                            selected: _paymentMethod == PaymentMethod.cash,
                            onTap: () => setState(() {
                              _paymentMethod = PaymentMethod.cash;
                              _changeError = null;
                              _stkStatus = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PaymentMethodCard(
                            icon: Icons.phone_android_rounded,
                            label: 'M-Pesa',
                            selected: _paymentMethod == PaymentMethod.stk,
                            onTap: () => setState(() {
                              _paymentMethod = PaymentMethod.stk;
                              _changeError = null;
                              _stkStatus = null;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_paymentMethod == PaymentMethod.cash)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount received',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountReceivedController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                        decoration: InputDecoration(
                          hintText: formatKes(total),
                          hintStyle: TextStyle(color: cs.onSurfaceVariant.withAlpha(180), fontSize: 18),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'Ksh',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 60, minHeight: 52),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withAlpha(120),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: cs.outline.withAlpha(100)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: cs.outline.withAlpha(100)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: cs.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final amt in _quickAmounts())
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Builder(
                                  builder: (ctx) {
                                    final recv = _amountReceived;
                                    final match = recv != null && (recv - amt).abs() < 0.01;
                                    final fd = (amt % 1 == 0) ? 0 : 2;
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          _amountReceivedController.text = fd == 0 ? amt.toStringAsFixed(0) : amt.toStringAsFixed(2);
                                          setState(() {});
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: match ? cs.primary : cs.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: match ? cs.primary : cs.outline.withAlpha(100),
                                            ),
                                          ),
                                          child: Text(
                                            formatKes(amt, fractionDigits: fd),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: match ? Colors.white : cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_amountReceived != null && _amountReceived! >= total) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kPrimary.withAlpha(14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kPrimary.withAlpha(45)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: kPrimary.withAlpha(22),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.change_circle_rounded, color: kPrimary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Change to give back',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formatKes(_change),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: kPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_amountReceived != null && _amountReceived! < total) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kError.withAlpha(14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kError.withAlpha(45)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: kError, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Short by ${formatKes(total - _amountReceived!)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: kError,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (_paymentMethod == PaymentMethod.stk)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer phone number',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                              border: Border.all(color: cs.outline.withAlpha(100)),
                            ),
                            child: Text(
                              _mpesaPrefix,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _mpesaDigitsController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              maxLength: 9,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
                              decoration: InputDecoration(
                                hintText: '7XXXXXXXX',
                                counterText: '',
                                filled: true,
                                fillColor: cs.surfaceContainerHighest.withAlpha(120),
                                border: OutlineInputBorder(
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                                  borderSide: BorderSide(color: cs.outline.withAlpha(100)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kPrimary.withAlpha(12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kPrimary.withAlpha(38)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: kPrimary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'STK push for ${formatKes(total)}. Ensure Shop Settings M-Pesa matches your live Daraja app (same as web).',
                                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_stkStatus != null && _paymentMethod == PaymentMethod.stk)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    _stkStatus!,
                    style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            if (_changeError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    _changeError!,
                    style: TextStyle(color: cs.error, fontSize: 13),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: cs.surface,
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.paddingOf(context).bottom + 14),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outline.withAlpha(80))),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withAlpha(24),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
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
                backgroundColor: kPrimary,
                disabledBackgroundColor: kPrimary.withAlpha(120),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _paymentMethod == PaymentMethod.cash
                              ? Icons.check_circle_rounded
                              : Icons.send_to_mobile_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _paymentMethod == PaymentMethod.cash ? 'Complete sale' : 'Send M-Pesa request',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
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

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF1B8B5A), Color(0xFF26B573)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(160),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? Colors.transparent : Theme.of(context).colorScheme.outline.withAlpha(100),
              width: 0.9,
            ),
            boxShadow: selected
                ? [BoxShadow(color: kPrimary.withAlpha(55), blurRadius: 14, offset: const Offset(0, 5))]
                : [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 26,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(160),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

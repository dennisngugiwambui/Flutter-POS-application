import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/profile_page.dart';
import '../../products/presentation/products_page.dart';
import 'client_purchases_page.dart';

/// Bottom navigation for registered clients: browse catalog and profile (no POS).
class ClientMainShell extends ConsumerStatefulWidget {
  const ClientMainShell({super.key});

  @override
  ConsumerState<ClientMainShell> createState() => _ClientMainShellState();
}

class _ClientMainShellState extends ConsumerState<ClientMainShell> {
  int _tab = 0;
  DateTime? _lastBackAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final pages = [
      ClientPurchasesPage(onBrowseProducts: () => setState(() => _tab = 1)),
      const ProductsPage(),
      const ProfilePage(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_tab != 0) {
          setState(() => _tab = 0);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        final now = DateTime.now();
        if (_lastBackAt != null && now.difference(_lastBackAt!).inSeconds < 2) {
          SystemNavigator.pop();
          return;
        }
        _lastBackAt = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: theme.colorScheme.surface,
          systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          body: IndexedStack(index: _tab, children: pages),
          bottomNavigationBar: _ClientBottomNav(
            current: _tab,
            onTap: (i) => setState(() => _tab = i),
          ),
        ),
      ),
    );
  }
}

class _ClientBottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _ClientBottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outline, width: 0.9)),
        boxShadow: [
          BoxShadow(color: cs.shadow.withAlpha(24), blurRadius: 18, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(icon: Icons.receipt_long_rounded, label: 'Purchases', idx: 0, cur: current, onTap: onTap),
              _NavItem(icon: Icons.inventory_2_rounded, label: 'Products', idx: 1, cur: current, onTap: onTap),
              _NavItem(icon: Icons.person_rounded, label: 'Profile', idx: 2, cur: current, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int idx;
  final int cur;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.idx,
    required this.cur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = idx == cur;
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final muted = cs.onSurfaceVariant;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 34,
              decoration: BoxDecoration(
                color: active ? primary.withAlpha(40) : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: active ? primary : muted),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? primary : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

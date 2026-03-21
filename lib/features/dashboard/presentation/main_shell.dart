import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/app_theme.dart';
import 'dashboard_page.dart';
import '../../products/presentation/products_page.dart';
import '../../sale/presentation/sale_page.dart';
import '../../auth/presentation/profile_page.dart';
import '../../settings/presentation/shop_settings_page.dart';

final mainShellTabProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  DateTime? _lastBackAt;

  static const List<Widget> _pages = [
    DashboardPage(),
    ProductsPage(),
    SalePage(),
    ProfilePage(),
    ShopSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(mainShellTabProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (tab != 0) {
          ref.read(mainShellTabProvider.notifier).state = 0;
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
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: kSurface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          body: IndexedStack(index: tab, children: _pages),
          bottomNavigationBar: _BottomNav(
            current: tab,
            onTap: (i) => ref.read(mainShellTabProvider.notifier).state = i,
          ),
        ),
      ),
    );
  }
}

// ── Bottom navigation bar ──────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kBorder, width: 0.9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0A2018),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', idx: 0, cur: current, onTap: onTap),
              _NavItem(icon: Icons.inventory_2_rounded, label: 'Products', idx: 1, cur: current, onTap: onTap),

              // Centre POS button
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B8B5A), Color(0xFF26B573)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withAlpha(75),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.point_of_sale_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

              _NavItem(icon: Icons.person_rounded, label: 'Profile', idx: 3, cur: current, onTap: onTap),
              _NavItem(icon: Icons.tune_rounded, label: 'More', idx: 4, cur: current, onTap: onTap),
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
                color: active ? kPrimary.withAlpha(18) : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: active ? kPrimary : kTextMuted),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? kPrimary : kTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

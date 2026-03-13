import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dashboard_page.dart';
import '../../sale/presentation/sale_page.dart';
import '../../products/presentation/product_list_page.dart';
import '../../products/presentation/add_product_page.dart';
import '../../settings/presentation/shop_settings_page.dart';
import '../../sale/presentation/sales_history_page.dart';
import '../../../dashboard_provider.dart';
import '../../auth/presentation/profile_page.dart';
import '../../auth/presentation/login_page.dart';
import '../../auth/presentation/auth_provider.dart';

final mainShellTabProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const int _salesIndex = 2;
  DateTime? _lastBackAt;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Products'),
    _NavItem(icon: Icons.point_of_sale_rounded, label: 'Sales'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    _NavItem(icon: Icons.settings_rounded, label: 'Others'),
  ];

  List<Widget> get _pages => [
    const DashboardPage(),
    _ProductsTabWithNavigator(),
    const SalePage(),
    const ProfilePage(),
    const ShopSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainShellTabProvider);
    final theme = Theme.of(context);

    final topPadding = MediaQuery.of(context).padding.top;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentIndex != 0) {
          ref.read(mainShellTabProvider.notifier).state = 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Press back again to exit'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
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
          SnackBar(
            content: const Text('Press back again to exit'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: _buildDrawer(context),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // Top bar: sidebar toggle + page title (small, spaced so they don't override)
              Padding(
                padding: EdgeInsets.only(top: topPadding, left: 8, right: 8, bottom: 8),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: Icon(Icons.menu_rounded, color: theme.colorScheme.onSurface, size: 24),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          minimumSize: const Size(44, 44),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                      _navItems[currentIndex].label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: currentIndex,
                children: _pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildUShapedNavBar(currentIndex),
    ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: profileAsync.when(
                data: (profile) => Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        profile?.fullName.isNotEmpty == true ? profile!.fullName[0].toUpperCase() : 'U',
                        style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.fullName ?? 'User',
                            style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          Text(
                            profile?.email ?? '',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) => ListTile(title: Text('Profile', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
              ),
            ),
            Divider(color: theme.colorScheme.outline.withAlpha(80), height: 1),
            _drawerTile(Icons.home_rounded, 'Home', 0),
            _drawerTile(Icons.inventory_2_rounded, 'Products', 1),
            _drawerTile(Icons.point_of_sale_rounded, 'Sales', 2),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Icon(Icons.history_rounded, color: theme.colorScheme.onSurfaceVariant, size: 22),
              title: Text('Sales History', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryPage()));
              },
            ),
            _drawerTile(Icons.person_rounded, 'Profile', 3),
            _drawerTile(Icons.settings_rounded, 'Settings', 4),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error, size: 22),
              title: Text('Sign Out', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String label, int index) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 22),
      title: Text(label, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15)),
      onTap: () {
        ref.read(mainShellTabProvider.notifier).state = index;
        Navigator.pop(context);
      },
    );
  }

  Widget _buildUShapedNavBar(int currentIndex) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Bar with U-cutout in the middle
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 20, offset: const Offset(0, -4)),
              ],
              border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(40)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNormalNavItem(0, currentIndex),
                _buildNormalNavItem(1, currentIndex),
                const SizedBox(width: 72), // Space for center button
                _buildNormalNavItem(3, currentIndex),
                _buildNormalNavItem(4, currentIndex),
              ],
            ),
          ),
          // Center U-shaped raised Sales button
          Positioned(
            bottom: 24,
            child: GestureDetector(
              onTap: () => ref.read(mainShellTabProvider.notifier).state = _salesIndex,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withAlpha(150),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.point_of_sale_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalNavItem(int index, int currentIndex) {
    final item = _navItems[index];
    final isSelected = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(mainShellTabProvider.notifier).state = index,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _ProductsTabWithNavigator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/add':
            return MaterialPageRoute(builder: (_) => const AddProductPage());
          default:
            return MaterialPageRoute(builder: (_) => const ProductListPage());
        }
      },
    );
  }
}

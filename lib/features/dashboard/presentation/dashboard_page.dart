import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../../dashboard_provider.dart';
import 'main_shell.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurf = colorScheme.onSurface;
    final onSurfVariant = colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  profileAsync.when(
                    data: (profile) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${profile?.fullName.split(' ').first ?? 'there'} 👋',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: onSurf),
                        ),
                        const SizedBox(height: 4),
                        Text('Here\'s your business overview', style: TextStyle(color: onSurfVariant, fontSize: 14)),
                      ],
                    ),
                    loading: () => SizedBox(height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 1, color: colorScheme.primary))),
                    error: (_, __) => Text('Welcome!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: onSurf)),
                  ),
                  const SizedBox(height: 28),

                  _buildStatsGrid(ref, colorScheme),
                  const SizedBox(height: 28),

                  Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: onSurf)),
                  const SizedBox(height: 16),

                  _buildQuickActionsGrid(context, ref, colorScheme),
                  const SizedBox(height: 28),

                  Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: onSurf)),
                  const SizedBox(height: 12),
                  _buildRecentActivity(ref, colorScheme),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(WidgetRef ref, ColorScheme colorScheme) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    return statsAsync.when(
      data: (stats) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.55,
        children: [
          _buildStatCard('Total Sales', '\$${stats.totalSales.toStringAsFixed(0)}', Icons.trending_up_rounded, colorScheme.primary, colorScheme.secondary, colorScheme),
          _buildStatCard('Orders Today', '${stats.ordersToday}', Icons.receipt_long_rounded, colorScheme.tertiary, colorScheme.tertiary.withAlpha(180), colorScheme),
          _buildStatCard('Products', '${stats.productsCount}', Icons.inventory_2_rounded, const Color(0xFFF59E0B), const Color(0xFFFBBF24), colorScheme),
          _buildStatCard('Low Stock', '${stats.lowStockCount}', Icons.warning_rounded, colorScheme.error, colorScheme.error.withAlpha(180), colorScheme),
        ],
      ),
      loading: () => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.55,
        children: List.generate(4, (_) => Center(child: SizedBox(height: 40, width: 40, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)))),
      ),
      error: (_, __) => _buildStatsGridFallback(colorScheme),
    );
  }

  Widget _buildStatsGridFallback(ColorScheme colorScheme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.55,
      children: [
        _buildStatCard('Total Sales', '—', Icons.trending_up_rounded, colorScheme.primary, colorScheme.secondary, colorScheme),
        _buildStatCard('Orders Today', '—', Icons.receipt_long_rounded, colorScheme.tertiary, colorScheme.tertiary.withAlpha(180), colorScheme),
        _buildStatCard('Products', '—', Icons.inventory_2_rounded, const Color(0xFFF59E0B), const Color(0xFFFBBF24), colorScheme),
        _buildStatCard('Low Stock', '—', Icons.warning_rounded, colorScheme.error, colorScheme.error.withAlpha(180), colorScheme),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color1, Color color2, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1.withAlpha(30), color2.withAlpha(10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color1.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color1.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color1, size: 20),
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color1)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    final actions = [
      _QuickAction('New Sale', Icons.qr_code_scanner_rounded, colorScheme.primary, () {
        ref.read(mainShellTabProvider.notifier).state = 2;
      }),
      _QuickAction('Add Product', Icons.add_box_rounded, colorScheme.tertiary, () {
        ref.read(mainShellTabProvider.notifier).state = 1;
      }),
      _QuickAction('Products', Icons.inventory_2_rounded, const Color(0xFFF59E0B), () {
        ref.read(mainShellTabProvider.notifier).state = 1;
      }),
      _QuickAction('Settings', Icons.settings_rounded, colorScheme.secondary, () {
        ref.read(mainShellTabProvider.notifier).state = 4;
      }),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.7,
      children: actions.map((a) => _buildActionTile(a, colorScheme)).toList(),
    );
  }

  Widget _buildActionTile(_QuickAction action, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: action.color.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: action.color.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: action.color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(action.label, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(WidgetRef ref, ColorScheme colorScheme) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    return statsAsync.when(
      data: (stats) {
        if (stats.ordersToday == 0 && stats.lowStockCount == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('No recent activity yet', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
          );
        }
        final items = <(String, String, String, bool)>[];
        if (stats.ordersToday > 0) {
          items.add(('$stats.ordersToday order(s) today', 'Today', '\$${stats.totalSales.toStringAsFixed(0)} total', true));
        }
        if (stats.lowStockCount > 0) {
          items.add(('$stats.lowStockCount product(s) low on stock', 'Check products', 'Low stock', false));
        }
        return Column(
          children: items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withAlpha(40)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.$4 ? colorScheme.tertiary.withAlpha(25) : const Color(0xFFF59E0B).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.$4 ? Icons.receipt_rounded : Icons.warning_amber_rounded,
                  color: item.$4 ? colorScheme.tertiary : const Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$1, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(item.$2, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Text(item.$3, style: TextStyle(
                color: item.$4 ? colorScheme.tertiary : const Color(0xFFF59E0B),
                fontWeight: FontWeight.w700,
              )),
            ],
          ),
        )).toList(),
        );
      },
      loading: () => Padding(padding: const EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('Could not load activity', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.onTap);
}

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink(); // Replaced by BottomNav
  }
}

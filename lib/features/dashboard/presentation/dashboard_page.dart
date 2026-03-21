import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard_provider.dart';
import '../../../core/money_format.dart';
import 'main_shell.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurf = colorScheme.onSurface;

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
                    data: (profile) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withAlpha(80),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${profile?.fullName.split(' ').first ?? 'there'} 👋',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Here's your business overview",
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(200),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withAlpha(60)),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
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
                  const SizedBox(height: 100),
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
          _buildStatCard('Total Sales', formatKes(stats.totalSales, fractionDigits: 0), Icons.trending_up_rounded, colorScheme.primary, colorScheme.secondary, colorScheme),
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
          colors: [color1.withAlpha(22), color2.withAlpha(8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color1.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: color1.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color1.withAlpha(50), color2.withAlpha(30)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color1, size: 22),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color1.withAlpha(180),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color1,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(120),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: action.color.withAlpha(60)),
            boxShadow: [
              BoxShadow(
                color: action.color.withAlpha(20),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        action.color.withAlpha(40),
                        action.color.withAlpha(15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(action.icon, color: action.color, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Tap to open',
                          style: TextStyle(
                            color: action.color.withAlpha(180),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 10,
                          color: action.color.withAlpha(180),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          final o = stats.ordersToday;
          final orderLabel = o == 1 ? '1 sale today' : '$o sales today';
          items.add((orderLabel, 'Today', '${formatKes(stats.totalSales, fractionDigits: 0)} total', true));
        }
        if (stats.lowStockCount > 0) {
          final n = stats.lowStockCount;
          final lowLabel = n == 1 ? '1 product is low on stock' : '$n products are low on stock';
          items.add((lowLabel, 'Review inventory', 'Low stock', false));
        }
        return Column(
          children: items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(120),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline.withAlpha(45)),
                  boxShadow: [BoxShadow(color: colorScheme.shadow.withAlpha(20), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.$4 ? colorScheme.tertiary.withAlpha(30) : const Color(0xFFF59E0B).withAlpha(30),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item.$4 ? Icons.receipt_long_rounded : Icons.inventory_2_outlined,
                        color: item.$4 ? colorScheme.tertiary : const Color(0xFFF59E0B),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$1, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14, height: 1.25)),
                          const SizedBox(height: 4),
                          Text(item.$2, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, height: 1.3)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (item.$4 ? colorScheme.tertiary : const Color(0xFFF59E0B)).withAlpha(28),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.$3,
                        style: TextStyle(
                          color: item.$4 ? colorScheme.tertiary : const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
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
    return const SizedBox.shrink();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_theme.dart';
import '../../../core/ui_components.dart';
import '../../../core/money_format.dart';
import '../../../dashboard_provider.dart';
import 'main_shell.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // ── Top bar ────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: profileAsync.when(
                        data: (p) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good ${_greeting()},',
                              style: const TextStyle(
                                fontSize: 13,
                                color: kTextSub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p?.fullName.split(' ').first ?? 'there',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: kText,
                                letterSpacing: -0.7,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox(height: 44),
                        error: (_, __) => const Text(
                          'Welcome!',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kText),
                        ),
                      ),
                    ),
                    TopIconBtn(
                      icon: Icons.notifications_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Hero banner ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _HeroBanner(statsAsync: statsAsync),
            ),
          ),

          // ── Stats 2×2 grid ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: statsAsync.when(
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.65,
                  children: [
                    StatCard(
                      label: 'Total Sales',
                      value: formatKes(stats.totalSales, fractionDigits: 0),
                      icon: Icons.trending_up_rounded,
                      color: kPrimary,
                    ),
                    StatCard(
                      label: 'Orders Today',
                      value: '${stats.ordersToday}',
                      icon: Icons.receipt_long_rounded,
                      color: kAccent,
                    ),
                    StatCard(
                      label: 'Products',
                      value: '${stats.productsCount}',
                      icon: Icons.inventory_2_rounded,
                      color: kWarning,
                    ),
                    StatCard(
                      label: 'Low Stock',
                      value: '${stats.lowStockCount}',
                      icon: Icons.warning_amber_rounded,
                      color: kError,
                    ),
                  ],
                ),
                loading: () => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.65,
                  children: List.generate(
                    4,
                    (_) => Container(
                      decoration: BoxDecoration(
                        color: kSurface2,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Quick actions ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 14),
                  _QuickActionsGrid(ref: ref),
                ],
              ),
            ),
          ),

          // ── Recent activity ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Recent Activity'),
                  const SizedBox(height: 14),
                  _RecentActivity(statsAsync: statsAsync),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ── Hero banner ────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final AsyncValue<DashboardStatsData> statsAsync;
  const _HeroBanner({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B8B5A), Color(0xFF26B573)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withAlpha(70),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -28,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(18),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -32,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.storefront_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'POS System',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Business\nOverview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              statsAsync.when(
                data: (stats) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(22),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withAlpha(35)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${stats.ordersToday}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'orders',
                        style: TextStyle(
                          color: Colors.white.withAlpha(190),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'today',
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick actions grid ─────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final WidgetRef ref;
  const _QuickActionsGrid({required this.ref});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QA('New Sale', Icons.qr_code_scanner_rounded, kPrimary, () => ref.read(mainShellTabProvider.notifier).state = 2),
      _QA('Add Product', Icons.add_box_rounded, kAccent, () => ref.read(mainShellTabProvider.notifier).state = 1),
      _QA('Products', Icons.inventory_2_rounded, kWarning, () => ref.read(mainShellTabProvider.notifier).state = 1),
      _QA('Settings', Icons.tune_rounded, kPrimary, () => ref.read(mainShellTabProvider.notifier).state = 4),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.75,
      children: actions.map(_buildCard).toList(),
    );
  }

  Widget _buildCard(_QA a) {
    return GestureDetector(
      onTap: a.onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: a.color.withAlpha(45), width: 0.9),
          boxShadow: [
            BoxShadow(
              color: a.color.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(
              color: Color(0x080A2018),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: a.color.withAlpha(22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(a.icon, color: a.color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: kText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Open',
                      style: TextStyle(
                        fontSize: 10,
                        color: a.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 10, color: a.color),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QA {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QA(this.label, this.icon, this.color, this.onTap);
}

// ── Recent activity ────────────────────────────────────────────────────────────
class _RecentActivity extends StatelessWidget {
  final AsyncValue<DashboardStatsData> statsAsync;
  const _RecentActivity({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      data: (stats) {
        if (stats.ordersToday == 0 && stats.lowStockCount == 0) {
          return AppCard(
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: kSurface2,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.inbox_outlined, color: kTextMuted, size: 24),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No recent activity',
                  style: TextStyle(fontWeight: FontWeight.w700, color: kTextSub, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Start making sales to see activity here',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: kTextMuted),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            if (stats.ordersToday > 0)
              _activityRow(
                icon: Icons.receipt_rounded,
                color: kPrimary,
                title: '${stats.ordersToday} sale${stats.ordersToday > 1 ? 's' : ''} today',
                sub: 'Total: ${formatKes(stats.totalSales, fractionDigits: 0)}',
                badge: 'Revenue',
                badgeColor: kPrimary,
              ),
            if (stats.lowStockCount > 0) ...[
              const SizedBox(height: 10),
              _activityRow(
                icon: Icons.warning_amber_rounded,
                color: kError,
                title: '${stats.lowStockCount} item${stats.lowStockCount > 1 ? 's' : ''} low on stock',
                sub: 'Review your inventory',
                badge: 'Action needed',
                badgeColor: kError,
              ),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _activityRow({
    required IconData icon,
    required Color color,
    required String title,
    required String sub,
    required String badge,
    required Color badgeColor,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(22),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 11, color: kTextSub)),
              ],
            ),
          ),
          PillBadge(text: badge, color: badgeColor),
        ],
      ),
    );
  }
}

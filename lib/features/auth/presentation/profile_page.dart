import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_theme.dart';
import '../../../core/theme_context.dart';
import '../../../core/role_guard.dart';
import '../../../core/ui_components.dart';
import '../../../dashboard_provider.dart';
import '../../dashboard/presentation/main_shell.dart';
import '../../sale/presentation/sales_history_page.dart';
import '../../settings/presentation/shop_settings_page.dart';
import 'auth_provider.dart';
import 'user_management_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: context.appBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _FullHero(
              profileAsync: profileAsync,
              fadeAnim: _fadeAnim,
              slideAnim: _slideAnim,
            ),
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      profileAsync.maybeWhen(
                        data: (p) {
                          final r = p?.role.toLowerCase() ?? '';
                          if (r == 'client') {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel(context, 'ACCOUNT'),
                                _MenuCard(
                                  items: [
                                    MenuRow(
                                      icon: Icons.storefront_rounded,
                                      label: 'Catalog',
                                      subtitle: 'Browse products and send requests from product details',
                                      iconColor: kPrimary,
                                      iconBg: kPrimary.withAlpha(15),
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel(context, 'ACCOUNT'),
                              _MenuCard(
                                items: [
                                  MenuRow(
                                    icon: Icons.receipt_long_rounded,
                                    label: 'Sales History',
                                    subtitle: 'View all transactions',
                                    iconColor: kPrimary,
                                    iconBg: kPrimary.withAlpha(15),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SalesHistoryPage()),
                                    ),
                                  ),
                                  Divider(height: 1, color: context.appBorder.withAlpha(160), indent: 54),
                                  MenuRow(
                                    icon: Icons.tune_rounded,
                                    label: 'Shop Settings',
                                    subtitle: 'M-Pesa, printer, receipt',
                                    iconColor: kWarning,
                                    iconBg: kWarning.withAlpha(15),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ShopSettingsPage()),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (r == 'admin' || r == 'manager')
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionLabel(context, 'ADMINISTRATION'),
                                    _MenuCard(
                                      items: [
                                        MenuRow(
                                          icon: Icons.group_rounded,
                                          label: 'Manage Users',
                                          subtitle: 'Add or remove staff',
                                          iconColor: kAccent,
                                          iconBg: kAccent.withAlpha(15),
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const RoleGuard(
                                                allowedRoles: ['admin', 'manager'],
                                                child: UserManagementPage(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              if (r == 'cashier')
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionLabel(context, 'TEAM'),
                                    _MenuCard(
                                      items: [
                                        MenuRow(
                                          icon: Icons.groups_rounded,
                                          label: 'Active cashiers',
                                          subtitle: 'See who is on shift',
                                          iconColor: kAccent,
                                          iconBg: kAccent.withAlpha(15),
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const RoleGuard(
                                                allowedRoles: ['cashier'],
                                                child: UserManagementPage(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                            ],
                          );
                        },
                        orElse: () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel(context, 'ACCOUNT'),
                            _MenuCard(
                              items: [
                                MenuRow(
                                  icon: Icons.receipt_long_rounded,
                                  label: 'Sales History',
                                  subtitle: 'View all transactions',
                                  iconColor: kPrimary,
                                  iconBg: kPrimary.withAlpha(15),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SalesHistoryPage()),
                                  ),
                                ),
                                Divider(height: 1, color: context.appBorder.withAlpha(160), indent: 54),
                                MenuRow(
                                  icon: Icons.tune_rounded,
                                  label: 'Shop Settings',
                                  subtitle: 'M-Pesa, printer, receipt',
                                  iconColor: kWarning,
                                  iconBg: kWarning.withAlpha(15),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ShopSettingsPage()),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      _sectionLabel(context, 'APP'),
                      _MenuCard(
                        items: [
                          MenuRow(
                            icon: Icons.help_outline_rounded,
                            label: 'Help & Support',
                            subtitle: 'Get assistance',
                            iconColor: kInfo,
                            iconBg: kInfo.withAlpha(15),
                            onTap: () {},
                          ),
                          Divider(height: 1, color: context.appBorder.withAlpha(160), indent: 54),
                          MenuRow(
                            icon: Icons.info_outline_rounded,
                            label: 'About POS',
                            subtitle: 'Version 1.0.0',
                            iconColor: kTextSub,
                            iconBg: kSurface2,
                            onTap: () {},
                            trailing: const PillBadge(text: 'v1.0', color: kTextSub),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _MenuCard(
                        items: [
                          MenuRow(
                            icon: Icons.logout_rounded,
                            label: 'Sign Out',
                            isDestructive: true,
                            onTap: () => _signOut(context, ref),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: context.appTextMuted,
            letterSpacing: 0.9,
          ),
        ),
      );

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ctx.appSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: ctx.appBorder, width: 0.9),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kError.withAlpha(18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.logout_rounded, color: kError, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign Out?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ctx.appText),
            ),
            const SizedBox(height: 8),
            Text(
              'You will need to sign in again to access your POS.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ctx.appTextSub),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kError),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}

class _FullHero extends ConsumerWidget {
  final AsyncValue<dynamic> profileAsync;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;

  const _FullHero({
    required this.profileAsync,
    required this.fadeAnim,
    required this.slideAnim,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B8B5A), Color(0xFF26B573)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(12)),
            ),
          ),
          Positioned(
            left: -25,
            bottom: 40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(8)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
              child: FadeTransition(
                opacity: fadeAnim,
                child: SlideTransition(
                  position: slideAnim,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          TopIconBtn(
                            icon: Icons.menu_rounded,
                            bg: Colors.white.withAlpha(36),
                            iconColor: Colors.white,
                            onTap: () => MainShell.shellScaffoldKey.currentState?.openDrawer(),
                          ),
                          const SizedBox(width: 8),
                          TopIconBtn(
                            icon: Icons.home_rounded,
                            bg: Colors.white.withAlpha(36),
                            iconColor: Colors.white,
                            onTap: () => ref.read(mainShellTabProvider.notifier).state = 0,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const Spacer(),
                          profileAsync.maybeWhen(
                            data: (p) => p != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(22),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withAlpha(35)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF4DFFA0),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          p.role.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(),
                            orElse: () => const SizedBox(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      profileAsync.when(
                        data: (profile) => Column(
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.7, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.elasticOut,
                              builder: (_, v, child) => Transform.scale(scale: v, child: child),
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(40),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    (profile?.fullName.isNotEmpty == true)
                                        ? profile!.fullName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: kPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              profile?.fullName ?? 'User',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Supabase.instance.client.auth.currentUser?.email ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withAlpha(200),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _heroPill(label: 'Role', value: (profile?.role ?? '-').toUpperCase()),
                                const SizedBox(width: 10),
                                _heroPill(
                                  label: 'Status',
                                  value: (profile?.isActive != false) ? 'ACTIVE' : 'INACTIVE',
                                  valueColor: (profile?.isActive != false)
                                      ? const Color(0xFF4DFFA0)
                                      : Colors.white.withAlpha(200),
                                ),
                              ],
                            ),
                          ],
                        ),
                        loading: () => const SizedBox(height: 120),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPill({required String label, required String value, Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(170),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder, width: 0.9),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.shadow.withAlpha(24), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: items),
      ),
    );
  }
}

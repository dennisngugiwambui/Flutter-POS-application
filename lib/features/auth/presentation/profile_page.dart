import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_theme.dart';
import '../../../core/ui_components.dart';
import '../../../dashboard_provider.dart';
import '../../sale/presentation/sales_history_page.dart';
import '../../settings/presentation/shop_settings_page.dart';
import 'auth_provider.dart';
import 'user_management_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // ── Green hero header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHero(profileAsync: profileAsync),
          ),

          // ── Menu ───────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account section
                  _sectionLabel('ACCOUNT'),
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
                      Divider(height: 1, color: kBorder.withAlpha(180), indent: 54),
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

                  // Admin-only
                  profileAsync.maybeWhen(
                    data: (p) => p?.role == 'admin'
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('ADMINISTRATION'),
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
                                      MaterialPageRoute(builder: (_) => const UserManagementPage()),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  // App
                  _sectionLabel('APP'),
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
                      Divider(height: 1, color: kBorder.withAlpha(180), indent: 54),
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

                  // Sign out
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
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  static Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: kTextMuted,
            letterSpacing: 0.9,
          ),
        ),
      );

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(28),
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
            const Text(
              'Sign Out?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText),
            ),
            const SizedBox(height: 8),
            const Text(
              'You will need to sign in again to access your POS.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kTextSub),
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
    }
  }
}

// ── Green profile hero ─────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final AsyncValue<dynamic> profileAsync;
  const _ProfileHero({required this.profileAsync});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 290,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B8B5A), Color(0xFF26B573)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(15),
                  ),
                ),
              ),
              Positioned(
                left: -25,
                bottom: 30,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 36,
            decoration: const BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: Column(
              children: [
                Row(
                  children: [
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
                const SizedBox(height: 24),

                profileAsync.when(
                  data: (profile) => Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
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
                      const SizedBox(height: 12),
                      Text(
                        profile?.fullName ?? 'User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        Supabase.instance.client.auth.currentUser?.email ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha(200),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _heroPill(
                            label: 'Role',
                            value: (profile?.role ?? '-').toUpperCase(),
                          ),
                          const SizedBox(width: 10),
                          _heroPill(label: 'Status', value: 'ACTIVE', valueColor: const Color(0xFF4DFFA0)),
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
      ],
    );
  }

  Widget _heroPill({required String label, required String value, Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 1),
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

// ── Menu card ──────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final List<Widget> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder, width: 0.9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080A2018),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: items),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard_provider.dart';
import 'auth_provider.dart';
import 'login_page.dart';
import '../../settings/presentation/shop_settings_page.dart';
import 'admin_users_page.dart';
import '../domain/profile_model.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: profileAsync.when(
        data: (profile) => _buildContent(context, ref, profile, colorScheme, theme),
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (e, s) => Center(child: Text('Error loading profile', style: TextStyle(color: colorScheme.error))),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ProfileModel? profile, ColorScheme colorScheme, ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24, bottom: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withAlpha(150),
                  colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(120),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        profile?.fullName.isNotEmpty == true ? profile!.fullName[0].toUpperCase() : 'U',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: colorScheme.onPrimary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    profile?.fullName ?? 'Unknown User',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ) ?? TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(150),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.primary.withAlpha(80)),
                    ),
                    child: Text(
                      (profile?.role ?? 'cashier').toUpperCase(),
                      style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('MY INFORMATION', style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildInfoCard([
                  _InfoItem(Icons.email_outlined, 'Email', profile?.email ?? '-'),
                  _InfoItem(Icons.phone_outlined, 'Phone Number', profile?.phoneNumber ?? '-'),
                  _InfoItem(Icons.badge_outlined, 'Role', (profile?.role ?? '-').toUpperCase()),
                  _InfoItem(Icons.calendar_today_outlined, 'Member Since', _formatDate(profile?.createdAt)),
                ], colorScheme),
                const SizedBox(height: 24),
                Text('ACTIONS', style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildActionCard([
                  _ActionItem(Icons.settings_outlined, 'Shop Settings', colorScheme.primary, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopSettingsPage()));
                  }),
                  if (profile?.role == 'admin')
                    _ActionItem(Icons.people_outline_rounded, 'Manage Users', colorScheme.secondary, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersPage()));
                    }),
                  _ActionItem(Icons.logout_rounded, 'Sign Out', colorScheme.error, () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                    }
                  }),
                ], colorScheme),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<_InfoItem> items, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withAlpha(40)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(120),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(items[i].icon, color: colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].title, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(items[i].value, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < items.length - 1) Divider(height: 1, color: colorScheme.outline.withAlpha(40), indent: 74, endIndent: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(List<_ActionItem> items, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withAlpha(40)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: items[i].onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: items[i].color.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(items[i].icon, color: items[i].color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text(items[i].label, style: TextStyle(
                      color: items[i].label == 'Sign Out' ? colorScheme.error : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    )),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant, size: 22),
                  ],
                ),
              ),
            ),
            if (i < items.length - 1) Divider(height: 1, color: colorScheme.outline.withAlpha(40), indent: 74, endIndent: 20),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _InfoItem {
  final IconData icon;
  final String title;
  final String value;
  const _InfoItem(this.icon, this.title, this.value);
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem(this.icon, this.label, this.color, this.onTap);
}

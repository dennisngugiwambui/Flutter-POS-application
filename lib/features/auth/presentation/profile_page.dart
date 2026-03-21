import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard_provider.dart';
import 'auth_provider.dart';
import 'login_page.dart';
import '../../settings/presentation/shop_settings_page.dart';
import 'admin_users_page.dart';
import '../domain/profile_model.dart';
import '../../sale/presentation/sales_history_page.dart';
import 'package:shop/screens/profile/views/components/profile_card.dart';
import 'package:shop/screens/profile/views/components/profile_menu_item_list_tile.dart';

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
        data: (profile) => _buildContent(context, ref, profile, colorScheme),
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (e, s) => Center(child: Text('Error loading profile', style: TextStyle(color: colorScheme.error))),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ProfileModel? profile, ColorScheme colorScheme) {
    // Use template-styled profile card + list tiles, but keep your POS actions.
    return ListView(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Material(
            color: colorScheme.surfaceContainerHighest.withAlpha(90),
            borderRadius: BorderRadius.circular(20),
            child: ProfileCard(
              name: profile?.fullName ?? 'User',
              email: profile?.email ?? '',
              imageSrc: '',
              press: null,
              isShowHi: true,
              isShowArrow: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              ProfileMenuListTile(
                text: 'Sales History',
                svgSrc: 'assets/icons/Order.svg',
                press: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalesHistoryPage()),
                ),
              ),
              ProfileMenuListTile(
                text: 'Shop Settings',
                svgSrc: 'assets/icons/Preferences.svg',
                press: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShopSettingsPage()),
                ),
              ),
              if (profile?.role == 'admin')
                ProfileMenuListTile(
                  text: 'Manage Users',
                  svgSrc: 'assets/icons/FAQ.svg',
                  press: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminUsersPage()),
                  ),
                ),
              ListTile(
                onTap: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                minLeadingWidth: 24,
                leading: Icon(Icons.logout_rounded, color: colorScheme.error),
                title: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_theme.dart';
import '../../../core/ui_components.dart';
import '../domain/profile_model.dart';
import 'create_employee_sheet.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  List<ProfileModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client.from('profiles').select().order('full_name');
      setState(() {
        _users = (res as List).map((e) => ProfileModel.fromJson(Map<String, dynamic>.from(e))).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(ProfileModel user) async {
    if (user.id == null) return;
    final newVal = user.isActive == true ? false : true;
    await Supabase.instance.client.from('profiles').update({'is_active': newVal}).eq('id', user.id!);
    _loadUsers();
  }

  Future<void> _changeRole(ProfileModel user, String newRole) async {
    if (user.id == null) return;
    await Supabase.instance.client.from('profiles').update({'role': newRole}).eq('id', user.id!);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    TopIconBtn(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'User Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: kText,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    TopIconBtn(
                      icon: Icons.refresh_rounded,
                      onTap: _loadUsers,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Summary strip ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    _summaryCol('Total', '${_users.length}', kPrimary),
                    _vertDiv(),
                    _summaryCol('Admins', '${_users.where((u) => u.role == 'admin').length}', kWarning),
                    _vertDiv(),
                    _summaryCol('Active', '${_users.where((u) => u.isActive != false).length}', kAccent),
                  ],
                ),
              ),
            ),
          ),

          // ── User list ──────────────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                ),
              ),
            )
          else if (_users.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: kSurface2,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.group_outlined, size: 30, color: kTextMuted),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No users found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kText),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UserCard(
                      user: _users[i],
                      onToggleActive: () => _toggleActive(_users[i]),
                      onRoleChanged: (r) => _changeRole(_users[i], r),
                    ),
                  ),
                  childCount: _users.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),

      // ── FAB ─────────────────────────────────────────────────────────────────────
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B8B5A), Color(0xFF26B573)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showAddEmployee(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add Employee',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCol(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: kTextSub, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _vertDiv() => Container(
        width: 0.9,
        height: 36,
        color: kBorder,
      );

  Future<void> _showAddEmployee(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const CreateEmployeeSheet(),
    );
    if (!context.mounted) return;
    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee created. You can activate/deactivate them in the list.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    await _loadUsers();
  }
}

// ── User card ──────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final ProfileModel user;
  final VoidCallback onToggleActive;
  final ValueChanged<String> onRoleChanged;

  const _UserCard({
    required this.user,
    required this.onToggleActive,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = user.isActive != false;
    final isAdmin = user.role == 'admin';

    final parts = user.fullName.split(' ').where((w) => w.isNotEmpty).toList();
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : user.fullName.isNotEmpty
            ? user.fullName[0].toUpperCase()
            : '?';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isAdmin ? kWarning.withAlpha(22) : kPrimary.withAlpha(18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isAdmin ? kWarning : kPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 12, color: kTextSub),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showRoleSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAdmin ? kWarning.withAlpha(18) : kPrimary.withAlpha(15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isAdmin ? kWarning.withAlpha(55) : kPrimary.withAlpha(45),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isAdmin ? kWarning : kPrimary,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 13,
                              color: isAdmin ? kWarning : kPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PillBadge(
                      text: isActive ? 'ACTIVE' : 'INACTIVE',
                      color: isActive ? kPrimary : kError,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          GestureDetector(
            onTap: onToggleActive,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 26,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF1B8B5A), Color(0xFF26B573)],
                      )
                    : null,
                color: isActive ? null : kSurface2,
                borderRadius: BorderRadius.circular(13),
                border: isActive ? null : Border.all(color: kBorder, width: 0.9),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
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

  void _showRoleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Role',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kText),
            ),
            const SizedBox(height: 16),
            for (final role in ['admin', 'manager', 'cashier'])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onRoleChanged(role);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: user.role == role ? kPrimary.withAlpha(15) : kSurface2,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: user.role == role ? kPrimary.withAlpha(55) : kBorder,
                        width: 0.9,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: user.role == role ? kPrimary.withAlpha(18) : kSurface,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            role == 'admin'
                                ? Icons.admin_panel_settings_rounded
                                : role == 'manager'
                                    ? Icons.manage_accounts_rounded
                                    : Icons.point_of_sale_rounded,
                            color: user.role == role ? kPrimary : kTextSub,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          role[0].toUpperCase() + role.substring(1),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: user.role == role ? kPrimary : kText,
                          ),
                        ),
                        const Spacer(),
                        if (user.role == role) const Icon(Icons.check_circle_rounded, color: kPrimary, size: 20),
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
}

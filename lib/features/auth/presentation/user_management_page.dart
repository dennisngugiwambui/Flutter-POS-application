import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_theme.dart';
import '../../../core/theme_context.dart';
import '../../../core/ui_components.dart';
import '../../../dashboard_provider.dart';
import '../domain/profile_model.dart';
import 'create_employee_sheet.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage>
    with SingleTickerProviderStateMixin {
  List<ProfileModel> _users = [];
  bool _loading = true;
  late TabController _tabs;
  static const _tabsList = ['All', 'Admin', 'Manager', 'Cashier', 'Client'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabsList.length, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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

  List<ProfileModel> _filtered(String tab) {
    if (tab == 'All') return _users;
    final r = tab.toLowerCase();
    if (tab == 'Client') {
      return _users.where((u) => u.role.toLowerCase() == 'client').toList();
    }
    return _users.where((u) => u.role.toLowerCase() == r).toList();
  }

  Future<void> _toggleActive(ProfileModel user) async {
    if (user.id == null) return;
    final newVal = user.isActive != true;
    final ok = await _showConfirmModal(
      context: context,
      icon: newVal ? Icons.check_circle_rounded : Icons.block_rounded,
      iconColor: newVal ? kPrimary : kError,
      title: newVal ? 'Activate User?' : 'Deactivate User?',
      message: newVal
          ? '${user.fullName} will be able to access the system.'
          : '${user.fullName} will lose access immediately.',
      confirmLabel: newVal ? 'Activate' : 'Deactivate',
      confirmColor: newVal ? kPrimary : kError,
    );
    if (ok != true) return;
    try {
      final res = await Supabase.instance.client.from('profiles').update({'is_active': newVal}).eq('id', user.id!).select();
      if (res.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not update status (no permission or user missing).'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: kError,
          ),
        );
        return;
      }
      await _loadUsers();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kError,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kError,
        ),
      );
    }
  }

  Future<void> _changeRole(ProfileModel user, String newRole) async {
    if (user.id == null) return;
    try {
      await Supabase.instance.client.rpc(
        'staff_set_user_role',
        params: {
          'p_target_user_id': user.id!,
          'p_new_role': newRole,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.fullName} is now ${newRole[0].toUpperCase()}${newRole.substring(1)}.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimary,
        ),
      );
      await _loadUsers();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kError,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kError,
        ),
      );
    }
  }

  Future<bool?> _showConfirmModal({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showModalBottomSheet<bool>(
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
              decoration: BoxDecoration(color: iconColor.withAlpha(18), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ctx.appText)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: ctx.appTextSub)),
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
                    style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCashier = ref.watch(profileProvider).maybeWhen(
          data: (p) => p?.role.toLowerCase() == 'cashier',
          orElse: () => false,
        );
    final isStaff = ref.watch(profileProvider).maybeWhen(
          data: (p) {
            final r = p?.role.toLowerCase() ?? '';
            return r == 'admin' || r == 'manager';
          },
          orElse: () => false,
        );

    if (isCashier) {
      final peers = _users
          .where((u) => u.role.toLowerCase() == 'cashier' && u.isActive != false)
          .toList();
      return Scaffold(
        backgroundColor: context.appBg,
        body: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                TopIconBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Active cashiers',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: context.appText,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                TopIconBtn(icon: Icons.refresh_rounded, onTap: _loadUsers),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'You can see fellow cashiers who are active. Status changes are managed by a manager or admin.',
                              style: TextStyle(fontSize: 13, color: context.appTextSub, height: 1.35),
                            ),
                            const SizedBox(height: 14),
                            AppCard(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(Icons.groups_rounded, color: kPrimary, size: 22),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${peers.length} active',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: context.appText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (peers.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No active cashiers listed',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.appTextSub),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CashierPeerCard(user: peers[i]),
                          ),
                          childCount: peers.length,
                        ),
                      ),
                    ),
                ],
              ),
      );
    }

    return Scaffold(
      backgroundColor: context.appBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        TopIconBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'User Management',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: context.appText,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        TopIconBtn(icon: Icons.refresh_rounded, onTap: _loadUsers),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _summaryCol(context, 'Total', '${_users.length}', kPrimary),
                            _vertDiv(),
                            _summaryCol(context, 'Admins', '${_users.where((u) => u.role.toLowerCase() == 'admin').length}', kWarning),
                            _vertDiv(),
                            _summaryCol(
                              context,
                              'Managers',
                              '${_users.where((u) => u.role.toLowerCase() == 'manager').length}',
                              kAccent,
                            ),
                            _vertDiv(),
                            _summaryCol(
                              context,
                              'Cashiers',
                              '${_users.where((u) => u.role.toLowerCase() == 'cashier').length}',
                              kInfo,
                            ),
                            _vertDiv(),
                            _summaryCol(
                              context,
                              'Clients',
                              '${_users.where((u) => u.role.toLowerCase() == 'client').length}',
                              kGold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.appBorder, width: 0.9),
                      ),
                      child: TabBar(
                        controller: _tabs,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: Colors.white,
                        unselectedLabelColor: context.appTextSub,
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        indicator: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1B8B5A), Color(0xFF26B573)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        padding: const EdgeInsets.all(4),
                        tabs: _tabsList.map((t) => Tab(text: t, height: 36)).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
        body: _loading
            ? const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                ),
              )
            : TabBarView(
                controller: _tabs,
                children: _tabsList.map((tab) {
                  final list = _filtered(tab);
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.group_outlined, size: 28, color: kTextMuted),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            tab == 'All' ? 'No users yet' : 'No ${tab}s yet',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.appTextSub),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    itemCount: list.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _UserCard(
                        user: list[i],
                        onToggle: () => _toggleActive(list[i]),
                        onRoleChanged: (r) => _changeRole(list[i], r),
                        onShowDetails: () => _showUserDetailSheet(context, list[i]),
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
      floatingActionButton: isStaff && _tabs.index == 0
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1B8B5A), Color(0xFF26B573)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: kPrimary.withAlpha(80), blurRadius: 16, offset: const Offset(0, 6))],
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
            )
          : null,
    );
  }

  Widget _summaryCol(BuildContext context, String label, String value, Color color) => SizedBox(
        width: 76,
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: context.appTextSub, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

  Widget _vertDiv() => Builder(
        builder: (context) => Container(width: 0.9, height: 32, color: context.appBorder),
      );

  void _showUserDetailSheet(BuildContext context, ProfileModel user) {
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat('MMM d, y • HH:mm');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: ctx.appSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: ctx.appBorder, width: 0.9),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'User details',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: cs.onSurface),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(user.fullName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface)),
            const SizedBox(height: 6),
            _detailRow(ctx, Icons.email_outlined, user.email),
            if (user.phoneNumber.isNotEmpty) _detailRow(ctx, Icons.phone_outlined, user.phoneNumber),
            const SizedBox(height: 12),
            _detailRow(
              ctx,
              Icons.badge_outlined,
              'Role: ${user.role.isEmpty ? '—' : '${user.role[0].toUpperCase()}${user.role.substring(1)}'}',
            ),
            _detailRow(
              ctx,
              user.isActive != false ? Icons.check_circle_outline_rounded : Icons.block_rounded,
              user.isActive != false ? 'Active' : 'Inactive',
            ),
            if (user.createdAt != null) _detailRow(ctx, Icons.event_outlined, df.format(user.createdAt!.toLocal())),
            const SizedBox(height: 8),
            Text(
              'Tip: tap the role pill to change role, or use the switch to activate/deactivate.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14, color: cs.onSurface, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEmployee(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => const CreateEmployeeSheet(),
    );
    if (!context.mounted) return;
    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Employee created successfully!',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      await _loadUsers();
    }
  }
}

// ── Read-only peer card (cashier view) ─────────────────────────────────────────
class _CashierPeerCard extends StatelessWidget {
  final ProfileModel user;

  const _CashierPeerCard({required this.user});

  @override
  Widget build(BuildContext context) {
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kPrimary, width: 2),
              color: kPrimary.withAlpha(18),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.appText),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 11, color: context.appTextSub),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const PillBadge(text: 'ACTIVE', color: kPrimary),
        ],
      ),
    );
  }
}

// ── User card ──────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final ProfileModel user;
  final VoidCallback onToggle;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onShowDetails;

  const _UserCard({
    required this.user,
    required this.onToggle,
    required this.onRoleChanged,
    required this.onShowDetails,
  });

  Color _roleColor(BuildContext context) {
    switch (user.role.toLowerCase()) {
      case 'admin':
        return kWarning;
      case 'manager':
        return kAccent;
      case 'client':
        return kInfo;
      default:
        return kPrimary;
    }
  }

  IconData get _roleIcon {
    switch (user.role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'manager':
        return Icons.manage_accounts_rounded;
      case 'client':
        return Icons.storefront_rounded;
      default:
        return Icons.point_of_sale_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final roleColor = _roleColor(context);
    final isActive = user.isActive != false;
    final parts = user.fullName.split(' ').where((w) => w.isNotEmpty).toList();
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : user.fullName.isNotEmpty
            ? user.fullName[0].toUpperCase()
            : '?';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: onShowDetails,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: roleColor, width: 2),
                        color: roleColor.withAlpha(18),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.appText,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: TextStyle(fontSize: 11, color: context.appTextSub),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _showRoleSheet(context),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: roleColor.withAlpha(15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: roleColor.withAlpha(55), width: 0.9),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_roleIcon, size: 11, color: roleColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.role.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: roleColor,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(Icons.expand_more_rounded, size: 12, color: roleColor),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              PillBadge(
                                text: isActive ? 'ACTIVE' : 'INACTIVE',
                                color: isActive ? kPrimary : kError,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
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
                color: isActive ? null : context.appSurface2,
                borderRadius: BorderRadius.circular(13),
                border: isActive ? null : Border.all(color: context.appBorder, width: 0.9),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 3)],
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
    final surface = context.appSurface;
    final surface2 = context.appSurface2;
    final border = context.appBorder;
    final textMain = context.appText;
    final textSub = context.appTextSub;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(28)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Role',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textMain),
              ),
              const SizedBox(height: 16),
              for (final entry in [
                ('admin', Icons.admin_panel_settings_rounded, kWarning, 'Full system access'),
                ('manager', Icons.manage_accounts_rounded, kAccent, 'Manage staff & reports'),
                ('cashier', Icons.point_of_sale_rounded, kPrimary, 'Process sales only'),
                ('client', Icons.storefront_rounded, kInfo, 'Customer / shop account'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onRoleChanged(entry.$1);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: user.role == entry.$1 ? entry.$3.withAlpha(12) : surface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: user.role == entry.$1 ? entry.$3.withAlpha(55) : border,
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: user.role == entry.$1 ? entry.$3.withAlpha(20) : surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(entry.$2, color: user.role == entry.$1 ? entry.$3 : textSub, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.$1[0].toUpperCase() + entry.$1.substring(1),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: user.role == entry.$1 ? entry.$3 : textMain,
                                  ),
                                ),
                                Text(entry.$4, style: TextStyle(fontSize: 11, color: textSub)),
                              ],
                            ),
                          ),
                          if (user.role == entry.$1) Icon(Icons.check_circle_rounded, color: entry.$3, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

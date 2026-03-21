import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile_model.dart';
import 'admin_user_detail_page.dart';
import 'create_employee_sheet.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  List<ProfileModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _users = (response as List).map((json) => ProfileModel.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRole(ProfileModel user, String newRole) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'role': newRole})
          .eq('id', user.id!);
      
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName}\'s role updated to $newRole'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _toggleActive(ProfileModel user) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'is_active': !user.isActive})
          .eq('id', user.id!);
      await _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showRoleDialog(ProfileModel user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurfaceVariant.withAlpha(51), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Change Role for ${user.fullName}', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            const SizedBox(height: 20),
            _roleOption(context, user, 'admin', Icons.admin_panel_settings_rounded, colorScheme.primary, 'Can manage everything'),
            _roleOption(context, user, 'cashier', Icons.point_of_sale_rounded, colorScheme.tertiary, 'Can only process sales'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _roleOption(BuildContext context, ProfileModel user, String role, IconData icon, Color color, String description) {
    final isSelected = user.role == role;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) _updateRole(user, role);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: isSelected ? color.withAlpha(25) : colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? color.withAlpha(60) : colorScheme.outline.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      Text(role.toUpperCase(), style: TextStyle(color: isSelected ? color : colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(description, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('User Management', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colorScheme.onSurfaceVariant),
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => const CreateEmployeeSheet(),
        ).then((created) {
          if (created == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Employee created. You can activate/deactivate them in the list.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          _loadUsers();
        }),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add employee'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : RefreshIndicator(
              onRefresh: _loadUsers,
              color: colorScheme.primary,
              child: _users.isEmpty
                  ? Center(child: Text('No users found', style: TextStyle(color: colorScheme.onSurfaceVariant)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) => _buildUserCard(context, _users[index]),
                    ),
            ),
    );
  }

  Widget _buildUserCard(BuildContext context, ProfileModel user) {
    final isAdmin = user.role == 'admin';
    final colorScheme = Theme.of(context).colorScheme;
    final roleColor = isAdmin ? colorScheme.primary : colorScheme.tertiary;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminUserDetailPage(user: user)),
      ).then((_) => _loadUsers()),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: roleColor.withAlpha(60),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorScheme.onPrimary),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(user.email, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showRoleDialog(user),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: roleColor.withAlpha(50)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(user.role.toUpperCase(), style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down_rounded, color: roleColor, size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.isActive ? colorScheme.tertiaryContainer.withAlpha(80) : colorScheme.errorContainer.withAlpha(80),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(color: user.isActive ? colorScheme.onTertiaryContainer : colorScheme.onErrorContainer, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(
              value: user.isActive,
              onChanged: (_) => _toggleActive(user),
              activeTrackColor: colorScheme.primaryContainer,
              activeThumbColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    ),
    );
  }
}

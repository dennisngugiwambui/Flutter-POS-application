import 'package:flutter/material.dart';
import '../domain/profile_model.dart';

class AdminUserDetailPage extends StatelessWidget {
  final ProfileModel user;

  const AdminUserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('User details', style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline.withAlpha(40)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                      style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                        const SizedBox(height: 2),
                        Text(user.email, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: user.isActive ? colorScheme.tertiaryContainer.withAlpha(100) : colorScheme.errorContainer.withAlpha(100),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      user.isActive ? 'ACTIVE' : 'PENDING',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: user.isActive ? colorScheme.onTertiaryContainer : colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _kv(context, 'Phone', user.phoneNumber.isEmpty ? '-' : user.phoneNumber),
            _kv(context, 'Role', user.role.toUpperCase()),
            _kv(context, 'Member since', user.createdAt != null ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}' : '-'),
            const Spacer(),
            Text(
              'Role and activation are managed from the User Management list.',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha(35)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(k, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13))),
          Text(v, style: TextStyle(color: colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}


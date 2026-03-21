import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard_provider.dart';
import 'app_theme.dart';

class RoleGuard extends ConsumerWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    return profileAsync.when(
      data: (p) {
        final role = (p?.role ?? 'cashier').toLowerCase();
        final allowed = allowedRoles.map((e) => e.toLowerCase()).toList();
        if (allowed.contains(role)) return child;
        return fallback ??
            Scaffold(
              backgroundColor: kBg,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: kError.withAlpha(15),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.lock_rounded, color: kError, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Access Denied',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'You do not have permission to view this page.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: kTextSub),
                      ),
                    ),
                  ],
                ),
              ),
            );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

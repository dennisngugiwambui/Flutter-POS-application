import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_theme.dart';
import '../../../dashboard_provider.dart';
import 'client_shell.dart';
import 'main_shell.dart';

class ShellRouter extends ConsumerWidget {
  const ShellRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    return profileAsync.when(
      data: (p) {
        if (p?.role.toLowerCase() == 'client') {
          return const ClientMainShell();
        }
        return const MainShell();
      },
      loading: () => const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      ),
      error: (_, __) => const MainShell(),
    );
  }
}

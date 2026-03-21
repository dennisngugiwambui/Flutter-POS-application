import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../sale/domain/sale_record_model.dart';
import '../../sale/data/sales_providers.dart';
import '../../../core/money_format.dart';
import '../../../core/theme_context.dart';

final clientPurchasesProvider = FutureProvider.family<List<SaleRecordModel>, String>((ref, userId) async {
  final repo = ref.read(salesRepositoryProvider);
  return repo.getSalesForCustomer(userId);
});

/// Client home: purchases linked to this account (requires `customer_user_id` on sales).
class ClientPurchasesPage extends ConsumerWidget {
  final VoidCallback onBrowseProducts;

  const ClientPurchasesPage({super.key, required this.onBrowseProducts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final dateFormat = DateFormat('MMM d, y • HH:mm');

    if (uid == null) {
      return Scaffold(
        backgroundColor: context.appBg,
        body: const Center(child: Text('Not signed in')),
      );
    }

    final async = ref.watch(clientPurchasesProvider(uid));

    return Scaffold(
      backgroundColor: context.appBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your purchases',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: context.appText,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Orders tied to your account appear here. Browse the catalogue anytime.',
                style: TextStyle(fontSize: 14, color: context.appTextSub, height: 1.45),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onBrowseProducts,
                  icon: Icon(Icons.inventory_2_rounded, color: Theme.of(context).colorScheme.primary),
                  label: const Text('Browse products', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: async.when(
                  data: (sales) {
                    if (sales.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 56, color: context.appTextMuted),
                              const SizedBox(height: 16),
                              Text(
                                'No purchases yet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: context.appText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'When your shop records a sale to your account, it will show up here. '
                                'You can still browse products and send requests from the Products tab.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: context.appTextSub, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: sales.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final s = sales[i];
                        final cs = Theme.of(ctx).colorScheme;
                        return Material(
                          color: cs.surfaceContainerHighest.withAlpha(90),
                          borderRadius: BorderRadius.circular(18),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              formatKes(s.totalAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                color: cs.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              dateFormat.format(s.createdAt),
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                            ),
                            trailing: Icon(Icons.chevron_right_rounded, color: cs.primary),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
                  error: (e, _) => Center(
                    child: Text('Could not load purchases: $e', style: TextStyle(color: context.appTextSub)),
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/domain/profile_model.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/dashboard/data/broadcast_repository.dart';
import 'features/dashboard/data/dashboard_stats_repository.dart';

final broadcastRepositoryProvider = Provider<BroadcastRepository>((ref) => BroadcastRepository());

final profileProvider = FutureProvider<ProfileModel?>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getProfile();
});

final dashboardStatsRepositoryProvider = Provider<DashboardStatsRepository>((ref) => DashboardStatsRepository());

final dashboardStatsProvider = FutureProvider<DashboardStatsData>((ref) async {
  final repo = ref.watch(dashboardStatsRepositoryProvider);
  final productsCount = await repo.getProductsCount();
  final lowStockCount = await repo.getLowStockCount();
  final totalSales = await repo.getTotalSales();
  final ordersToday = await repo.getOrdersTodayCount();
  return DashboardStatsData(
    totalSales: totalSales,
    ordersToday: ordersToday,
    productsCount: productsCount,
    lowStockCount: lowStockCount,
  );
});

class DashboardStatsData {
  final double totalSales;
  final int ordersToday;
  final int productsCount;
  final int lowStockCount;
  const DashboardStatsData({
    required this.totalSales,
    required this.ordersToday,
    required this.productsCount,
    required this.lowStockCount,
  });
}

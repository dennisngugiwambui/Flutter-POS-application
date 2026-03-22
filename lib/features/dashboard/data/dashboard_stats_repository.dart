import 'package:supabase_flutter/supabase_flutter.dart';
import '../../products/data/product_repository.dart';
import '../../sale/data/sales_repository.dart';
import '../../sale/domain/cart_item_model.dart';

class DashboardStatsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProductRepository _productRepo = ProductRepository();
  final SalesRepository _salesRepo = SalesRepository();

  Future<int> getProductsCount() async {
    final list = await _productRepo.getProducts();
    return list.length;
  }

  Future<int> getLowStockCount({int threshold = 5}) async {
    final list = await _productRepo.getProducts();
    return list.where((p) => p.stockQuantity < threshold).length;
  }

  Future<double> getTotalSales() async {
    final response = await _supabase.from('sales').select('total_amount');
    final list = response as List;
    double sum = 0;
    for (final row in list) {
      final v = row['total_amount'];
      if (v != null) sum += (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    }
    return sum;
  }

  Future<int> getOrdersTodayCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();
    final response = await _supabase
        .from('sales')
        .select('id')
        .gte('created_at', startOfDay)
        .lte('created_at', endOfDay);
    return (response as List).length;
  }

  /// Records a sale and its line items (for sales history detail).
  Future<void> recordSale(
    double totalAmount,
    List<CartItemModel> items, {
    String paymentMethod = 'cash',
  }) async {
    await _salesRepo.recordSale(
      totalAmount: totalAmount,
      items: items,
      paymentMethod: paymentMethod,
    );
  }
}

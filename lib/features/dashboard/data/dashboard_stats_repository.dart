import 'package:supabase_flutter/supabase_flutter.dart';
import '../../products/data/product_repository.dart';
import '../../sale/domain/cart_item_model.dart';

class DashboardStatsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProductRepository _productRepo = ProductRepository();

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
  Future<void> recordSale(double totalAmount, List<CartItemModel> items) async {
    final userId = _supabase.auth.currentUser?.id;
    final salesRes = await _supabase.from('sales').insert({
      'total_amount': totalAmount,
      if (userId != null) 'created_by': userId,
    }).select('id').single();
    final saleId = salesRes['id'] as String?;
    if (saleId == null || items.isEmpty) return;
    for (final item in items) {
      await _supabase.from('sale_items').insert({
        'sale_id': saleId,
        'product_id': item.product.id,
        'product_name': item.product.name,
        'barcode': item.product.barcode,
        'quantity': item.quantity,
        'unit_price': item.product.sellingPrice,
        'total_price': item.totalPrice,
        'image_url': item.product.imageUrl,
      });
    }
  }
}

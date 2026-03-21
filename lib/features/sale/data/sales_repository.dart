import 'package:supabase_flutter/supabase_flutter.dart';
import '../../products/data/product_repository.dart';
import '../domain/cart_item_model.dart';
import '../domain/sale_record_model.dart';
import '../domain/sale_item_model.dart';

class SalesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProductRepository _productRepo = ProductRepository();

  /// Inserts `sales` + `sale_items`, updates product stock, returns new sale id.
  Future<String> recordSale({
    required double totalAmount,
    required List<CartItemModel> items,
    String paymentMethod = 'cash',
    String? customerUserId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    final row = <String, dynamic>{
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      if (userId != null) 'created_by': userId,
      if (customerUserId != null) 'customer_user_id': customerUserId,
    };
    final salesRes = await _supabase.from('sales').insert(row).select('id').single();
    final saleId = salesRes['id'] as String?;
    if (saleId == null || items.isEmpty) {
      return saleId ?? '';
    }
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
    for (final item in items) {
      final id = item.product.id;
      if (id == null) continue;
      final newStock = (item.product.stockQuantity - item.quantity).clamp(0, 1 << 31);
      await _productRepo.updateStock(id, newStock);
    }
    return saleId;
  }

  /// Fetches sales with optional date range and created_by filter.
  Future<List<SaleRecordModel>> getSales({
    DateTime? startDate,
    DateTime? endDate,
    String? createdBy,
  }) async {
    var query = _supabase.from('sales').select();

    if (startDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day)
          .toUtc()
          .toIso8601String();
      query = query.gte('created_at', start);
    }
    if (endDate != null) {
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      ).toUtc().toIso8601String();
      query = query.lte('created_at', end);
    }
    if (createdBy != null && createdBy.isNotEmpty) {
      query = query.eq('created_by', createdBy);
    }

    final response = await query.order('created_at', ascending: false);
    final list = response as List;
    final sales = list.map((row) => SaleRecordModel.fromJson(Map<String, dynamic>.from(row))).toList();

    if (sales.isEmpty) return sales;

    final userIds = sales.map((s) => s.createdBy).whereType<String>().toSet().toList();
    if (userIds.isEmpty) return sales;

    final profilesRes = await _supabase.from('profiles').select('id, full_name').inFilter('id', userIds);
    final profilesMap = <String, String>{};
    for (final p in profilesRes as List) {
      final m = Map<String, dynamic>.from(p);
      profilesMap[m['id'] as String] = m['full_name'] as String? ?? '';
    }

    return sales.map((s) {
      return SaleRecordModel(
        id: s.id,
        totalAmount: s.totalAmount,
        createdBy: s.createdBy,
        createdAt: s.createdAt,
        sellerName: s.createdBy != null ? profilesMap[s.createdBy] : null,
      );
    }).toList();
  }

  /// Sales linked to a client account (`customer_user_id` on `sales`).
  Future<List<SaleRecordModel>> getSalesForCustomer(String customerUserId) async {
    final response = await _supabase
        .from('sales')
        .select()
        .eq('customer_user_id', customerUserId)
        .order('created_at', ascending: false);
    final list = response as List;
    final sales = list.map((row) => SaleRecordModel.fromJson(Map<String, dynamic>.from(row))).toList();

    if (sales.isEmpty) return sales;

    final userIds = sales.map((s) => s.createdBy).whereType<String>().toSet().toList();
    if (userIds.isEmpty) return sales;

    final profilesRes = await _supabase.from('profiles').select('id, full_name').inFilter('id', userIds);
    final profilesMap = <String, String>{};
    for (final p in profilesRes as List) {
      final m = Map<String, dynamic>.from(p);
      profilesMap[m['id'] as String] = m['full_name'] as String? ?? '';
    }

    return sales.map((s) {
      return SaleRecordModel(
        id: s.id,
        totalAmount: s.totalAmount,
        createdBy: s.createdBy,
        createdAt: s.createdAt,
        sellerName: s.createdBy != null ? profilesMap[s.createdBy] : null,
      );
    }).toList();
  }

  /// Fetches line items (products sold) for a given sale.
  Future<List<SaleItemModel>> getSaleItems(String saleId) async {
    final response = await _supabase
        .from('sale_items')
        .select()
        .eq('sale_id', saleId)
        .order('created_at', ascending: true);
    final list = response as List;
    return list.map((row) => SaleItemModel.fromJson(Map<String, dynamic>.from(row))).toList();
  }
}

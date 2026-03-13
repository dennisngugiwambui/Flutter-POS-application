import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/sale_record_model.dart';
import '../domain/sale_item_model.dart';

class SalesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

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

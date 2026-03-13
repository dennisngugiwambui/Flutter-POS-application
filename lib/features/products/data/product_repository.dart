import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/product_model.dart';
import 'dart:io';

class ProductRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ProductModel>> getProducts() async {
    final response = await _supabase
        .from('products')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => ProductModel.fromJson(json)).toList();
  }

  Future<void> addProduct(ProductModel product) async {
    await _supabase.from('products').insert(product.toJson());
  }

  Future<void> updateProduct(ProductModel product) async {
    if (product.id == null) return;
    await _supabase
        .from('products')
        .update(product.toJson())
        .eq('id', product.id!);
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);
  }

  /// Uploads image to Supabase storage. Returns public URL or empty string on failure.
  Future<String> uploadImage(File imageFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'product_images/$fileName';
    await _supabase.storage.from('products').upload(path, imageFile);
    return _supabase.storage.from('products').getPublicUrl(path);
  }

  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('barcode', barcode)
        .maybeSingle();
    
    if (response == null) return null;
    return ProductModel.fromJson(response);
  }

  /// Search products by barcode or name (case-insensitive, partial match).
  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.isEmpty) return [];
    final q = query.trim();
    final response = await _supabase
        .from('products')
        .select()
        .or('barcode.ilike.%$q%,name.ilike.%$q%')
        .order('created_at', ascending: false);
    return (response as List).map((json) => ProductModel.fromJson(json)).toList();
  }

  /// Update stock quantity explicitly (used after completing a sale).
  Future<void> updateStock(String id, int newQuantity) async {
    await _supabase
        .from('products')
        .update({'stock_quantity': newQuantity})
        .eq('id', id);
  }
}

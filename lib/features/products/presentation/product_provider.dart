import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/product_repository.dart';
import '../domain/product_model.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getProducts();
});

final productByBarcodeProvider = FutureProvider.family<ProductModel?, String>((ref, barcode) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getProductByBarcode(barcode);
});

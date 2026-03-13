import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:audioplayers/audioplayers.dart';
import '../domain/cart_item_model.dart';
import '../../products/presentation/product_provider.dart';
import '../../products/domain/product_model.dart';

class CartState {
  final List<CartItemModel> items;
  final bool isScanning;

  CartState({this.items = const [], this.isScanning = false});

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);

  CartState copyWith({List<CartItemModel>? items, bool? isScanning}) {
    return CartState(
      items: items ?? this.items,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref ref;
  final _audioPlayer = AudioPlayer();

  CartNotifier(this.ref) : super(CartState());

  /// Adds product by barcode (or increments if already in cart). Returns the product if found, null otherwise.
  Future<ProductModel?> addProductByBarcode(String barcode) async {
    final repository = ref.read(productRepositoryProvider);
    final product = await repository.getProductByBarcode(barcode);

    if (product == null) return null;

    // Play beep on successful find
    try {
      _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (_) {}

    final existingIndex = state.items.indexWhere((item) => item.product.barcode == barcode);
    final currentQty = existingIndex != -1 ? state.items[existingIndex].quantity : 0;
    final maxQty = product.stockQuantity;
    if (currentQty >= maxQty) {
      // Already at max stock, do not add more.
      return product;
    }

    final newQty = (currentQty + 1).clamp(1, maxQty);
    if (existingIndex != -1) {
      final updatedItems = List<CartItemModel>.from(state.items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(quantity: newQty);
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(items: [...state.items, CartItemModel(product: product, quantity: newQty)]);
    }
    return product;
  }

  void removeItem(String barcode) {
    state = state.copyWith(items: state.items.where((item) => item.product.barcode != barcode).toList());
  }

  void clearCart() {
    state = state.copyWith(items: []);
  }

  void updateQuantity(String barcode, int quantity) {
    if (quantity <= 0) {
      removeItem(barcode);
      return;
    }
    final updatedItems = state.items.map((item) {
      if (item.product.barcode == barcode) {
        final maxQty = item.product.stockQuantity;
        final clamped = quantity.clamp(1, maxQty);
        return item.copyWith(quantity: clamped);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

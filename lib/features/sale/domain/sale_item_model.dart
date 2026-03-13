/// One line item in a sale (product + quantity + price at time of sale).
class SaleItemModel {
  final String id;
  final String saleId;
  final String? productId;
  final String productName;
  final String barcode;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String imageUrl;

  SaleItemModel({
    required this.id,
    required this.saleId,
    this.productId,
    required this.productName,
    this.barcode = '',
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.imageUrl = '',
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id']?.toString() ?? '',
      saleId: json['sale_id']?.toString() ?? '',
      productId: json['product_id']?.toString(),
      productName: json['product_name']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toInt() : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      unitPrice: (json['unit_price'] is num) ? (json['unit_price'] as num).toDouble() : double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
      totalPrice: (json['total_price'] is num) ? (json['total_price'] as num).toDouble() : double.tryParse(json['total_price']?.toString() ?? '0') ?? 0,
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}

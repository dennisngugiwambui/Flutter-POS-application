class ProductModel {
  final String? id;
  final String name;
  final String barcode;
  final double buyingPrice;
  final double sellingPrice;
  final int stockQuantity;
  final String imageUrl;
  final String? createdBy;
  final DateTime? createdAt;

  ProductModel({
    this.id,
    required this.name,
    required this.barcode,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.imageUrl,
    this.createdBy,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      barcode: json['barcode'],
      buyingPrice: (json['buying_price'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      stockQuantity: json['stock_quantity'] as int,
      imageUrl: json['image_url'] ?? '',
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'barcode': barcode,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
      'image_url': imageUrl,
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}

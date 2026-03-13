class SaleRecordModel {
  final String id;
  final double totalAmount;
  final String? createdBy;
  final DateTime createdAt;
  final String? sellerName;

  SaleRecordModel({
    required this.id,
    required this.totalAmount,
    this.createdBy,
    required this.createdAt,
    this.sellerName,
  });

  factory SaleRecordModel.fromJson(Map<String, dynamic> json) {
    return SaleRecordModel(
      id: json['id'] ?? '',
      totalAmount: (json['total_amount'] is num)
          ? (json['total_amount'] as num).toDouble()
          : double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      sellerName: json['profiles']?['full_name'] ?? json['seller_name'],
    );
  }
}

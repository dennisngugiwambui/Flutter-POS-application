class ProfileModel {
  final String? id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  ProfileModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: json['role'] ?? 'cashier',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'is_active': isActive,
    };
  }
}

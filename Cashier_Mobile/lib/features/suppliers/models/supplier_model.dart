class SupplierModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? contactPerson;
  final double balance;
  final bool isActive;
  final String? syncStatus;

  SupplierModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.contactPerson,
    this.balance = 0,
    this.isActive = true,
    this.syncStatus,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      contactPerson: json['contactPerson'],
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] ?? true,
      syncStatus: json['syncStatus'],
    );
  }
}

class CreateSupplierRequest {
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? contactPerson;
  final double balance;

  CreateSupplierRequest({
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.contactPerson,
    this.balance = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'contactPerson': contactPerson,
    'balance': balance,
  };
}

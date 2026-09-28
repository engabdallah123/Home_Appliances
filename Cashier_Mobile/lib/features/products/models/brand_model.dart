class BrandModel {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String? description;
  final String? originCountry;
  final String? agentContactNumber;
  final bool isActive;
  final String syncStatus;

  BrandModel({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    this.description,
    this.originCountry,
    this.agentContactNumber,
    this.isActive = true,
    this.syncStatus = 'Synced',
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? (json['nameAr']?.toString() ?? ''),
      nameAr: json['nameAr']?.toString(),
      nameEn: json['nameEn']?.toString(),
      description: json['description']?.toString(),
      originCountry: json['originCountry']?.toString(),
      agentContactNumber: json['agentContactNumber']?.toString(),
      isActive: json['isActive'] ?? true,
      syncStatus: json['syncStatus']?.toString() ?? 'Synced',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'description': description,
    'originCountry': originCountry,
    'agentContactNumber': agentContactNumber,
    'isActive': isActive,
  };
}

class CreateBrandRequest {
  final String? name;
  final String? nameAr;
  final String? nameEn;
  final String? description;
  final String? originCountry;
  final String? agentContactNumber;

  CreateBrandRequest({
    this.name,
    this.nameAr,
    this.nameEn,
    this.description,
    this.originCountry,
    this.agentContactNumber,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'description': description,
    'originCountry': originCountry,
    'agentContactNumber': agentContactNumber,
  };
}

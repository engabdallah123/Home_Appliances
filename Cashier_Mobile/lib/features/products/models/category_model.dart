class CategoryModel {
  final String id;
  final String nameAr;
  final String? nameEn;
  final bool isActive;
  final String syncStatus;

  CategoryModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.isActive = true,
    this.syncStatus = 'Synced',
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      nameAr: json['nameAr'] ?? '',
      nameEn: json['nameEn'],
      isActive: json['isActive'] ?? true,
      syncStatus: json['syncStatus'] ?? 'Synced',
    );
  }

  Map<String, dynamic> toJson() => {
    'nameAr': nameAr,
    'nameEn': nameEn,
  };
}

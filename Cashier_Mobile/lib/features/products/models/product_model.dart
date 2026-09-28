class ProductModel {
  final String id;
  final String barcode;
  final String nameAr;
  final String? nameEn;
  final String baseUnit;
  final String? parentUnit;
  final int conversionFactor;
  final double purchasePrice;
  final double sellingPrice;
  final double wholesalePrice;
  final double stockQuantity;
  final String? categoryId;
  final String? categoryName;
  final bool isWeighable;
  final int shelfLifeDays;
  final int expiryAlertDays;
  final double reorderLevel;
  final bool trackExpiry;
  final bool isActive;
  final String syncStatus;

  // Home Appliances fields (الأجهزة الكهربائية والمنزلية)
  final String? brandId;
  final String? brandName;
  final String? modelNumber;
  final String? color;
  final int warrantyPeriodMonths;
  final String? maintenanceAgent;
  final bool hasSerialNumber;

  ProductModel({
    required this.id,
    required this.barcode,
    required this.nameAr,
    this.nameEn,
    this.baseUnit = 'قطعة',
    this.parentUnit = 'قطعة',
    this.conversionFactor = 1,
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.wholesalePrice = 0,
    this.stockQuantity = 0,
    this.categoryId,
    this.categoryName,
    this.isWeighable = false,
    this.shelfLifeDays = 30,
    this.expiryAlertDays = 3,
    this.reorderLevel = 5,
    this.trackExpiry = false,
    this.isActive = true,
    this.syncStatus = 'Synced',
    this.brandId,
    this.brandName,
    this.modelNumber,
    this.color,
    this.warrantyPeriodMonths = 12,
    this.maintenanceAgent,
    this.hasSerialNumber = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
      nameEn: json['nameEn']?.toString(),
      baseUnit: json['baseUnit']?.toString() ?? 'قطعة',
      parentUnit: json['parentUnit']?.toString() ?? 'قطعة',
      conversionFactor: (json['conversionFactor'] as num?)?.toInt() ?? 1,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (json['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      isWeighable: json['isWeighable'] ?? false,
      shelfLifeDays: (json['shelfLifeDays'] as num?)?.toInt() ?? 30,
      expiryAlertDays: (json['expiryAlertDays'] as num?)?.toInt() ?? 3,
      reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 5.0,
      trackExpiry: json['trackExpiry'] ?? false,
      isActive: json['isActive'] ?? true,
      syncStatus: json['syncStatus']?.toString() ?? 'Synced',
      brandId: json['brandId']?.toString(),
      brandName: json['brandName']?.toString(),
      modelNumber: json['modelNumber']?.toString(),
      color: json['color']?.toString(),
      warrantyPeriodMonths: (json['warrantyPeriodMonths'] as num?)?.toInt() ?? 12,
      maintenanceAgent: json['maintenanceAgent']?.toString(),
      hasSerialNumber: json['hasSerialNumber'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'baseUnit': baseUnit,
    'parentUnit': parentUnit,
    'conversionFactor': conversionFactor,
    'purchasePrice': purchasePrice,
    'sellingPrice': sellingPrice,
    'wholesalePrice': wholesalePrice,
    'initialStock': stockQuantity,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'isWeighable': isWeighable,
    'shelfLifeDays': shelfLifeDays,
    'expiryAlertDays': expiryAlertDays,
    'reorderLevel': reorderLevel,
    'trackExpiry': trackExpiry,
    'brandId': brandId,
    'brandName': brandName,
    'modelNumber': modelNumber,
    'color': color,
    'warrantyPeriodMonths': warrantyPeriodMonths,
    'maintenanceAgent': maintenanceAgent,
    'hasSerialNumber': hasSerialNumber,
  };
}

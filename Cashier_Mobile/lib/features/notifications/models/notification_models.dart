class ExpiryNotificationModel {
  final String id;
  final String productId;
  final String productName;
  final String? barcode;
  final String? batchId;
  final String? batchNumber;
  final double remainingQuantity;
  final String unit;
  final double unitCost;
  final DateTime? expiryDate;
  final int daysRemaining;
  final bool isExpired;
  final String message;
  final String status;

  ExpiryNotificationModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.barcode,
    this.batchId,
    this.batchNumber,
    required this.remainingQuantity,
    required this.unit,
    required this.unitCost,
    this.expiryDate,
    required this.daysRemaining,
    required this.isExpired,
    required this.message,
    required this.status,
  });

  factory ExpiryNotificationModel.fromJson(Map<String, dynamic> json) {
    return ExpiryNotificationModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] ?? '',
      barcode: json['barcode'],
      batchId: json['batchId']?.toString(),
      batchNumber: json['batchNumber'],
      remainingQuantity: (json['remainingQuantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'قطعة',
      unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0.0,
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate']) : null,
      daysRemaining: json['daysRemaining'] ?? 0,
      isExpired: json['isExpired'] ?? false,
      message: json['message'] ?? '',
      status: json['status'] ?? 'Active',
    );
  }
}

class LowStockProductModel {
  final String id;
  final String barcode;
  final String nameAr;
  final double stockQuantity;
  final double reorderLevel;
  final String baseUnit;
  final double purchasePrice;
  final double sellingPrice;
  final String? categoryName;

  LowStockProductModel({
    required this.id,
    required this.barcode,
    required this.nameAr,
    required this.stockQuantity,
    required this.reorderLevel,
    required this.baseUnit,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.categoryName,
  });

  factory LowStockProductModel.fromJson(Map<String, dynamic> json) {
    return LowStockProductModel(
      id: json['id']?.toString() ?? '',
      barcode: json['barcode'] ?? '',
      nameAr: json['nameAr'] ?? '',
      stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0.0,
      reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0.0,
      baseUnit: json['baseUnit'] ?? 'قطعة',
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      categoryName: json['categoryName']?.toString(),
    );
  }
}

class ShiftSummaryModel {
  final String id;
  final String shiftId;
  final String cashierName;
  final DateTime openedAt;
  final DateTime closedAt;
  final double openingCash;
  final double actualClosingCash;
  final double systemCash;
  final double cashDifference;
  final double totalSales;
  final double totalCash;
  final double totalCard;
  final double totalWallet;
  final double totalCredit;
  final int totalInvoices;
  final int totalReturns;
  final String? closingNotes;
  final bool isReadByOwner;
  final DateTime createdAt;

  ShiftSummaryModel({
    required this.id,
    required this.shiftId,
    required this.cashierName,
    required this.openedAt,
    required this.closedAt,
    required this.openingCash,
    required this.actualClosingCash,
    required this.systemCash,
    required this.cashDifference,
    required this.totalSales,
    required this.totalCash,
    required this.totalCard,
    required this.totalWallet,
    required this.totalCredit,
    required this.totalInvoices,
    required this.totalReturns,
    this.closingNotes,
    required this.isReadByOwner,
    required this.createdAt,
  });

  factory ShiftSummaryModel.fromJson(Map<String, dynamic> json) {
    return ShiftSummaryModel(
      id: json['id']?.toString() ?? '',
      shiftId: json['shiftId']?.toString() ?? '',
      cashierName: json['cashierName'] ?? 'كاشير',
      openedAt: DateTime.tryParse(json['openedAt'] ?? '') ?? DateTime.now(),
      closedAt: DateTime.tryParse(json['closedAt'] ?? '') ?? DateTime.now(),
      openingCash: (json['openingCash'] as num?)?.toDouble() ?? 0.0,
      actualClosingCash: (json['actualClosingCash'] as num?)?.toDouble() ?? 0.0,
      systemCash: (json['systemCash'] as num?)?.toDouble() ?? 0.0,
      cashDifference: (json['cashDifference'] as num?)?.toDouble() ?? 0.0,
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      totalCash: (json['totalCash'] as num?)?.toDouble() ?? 0.0,
      totalCard: (json['totalCard'] as num?)?.toDouble() ?? 0.0,
      totalWallet: (json['totalWallet'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (json['totalCredit'] as num?)?.toDouble() ?? 0.0,
      totalInvoices: json['totalInvoices'] ?? 0,
      totalReturns: json['totalReturns'] ?? 0,
      closingNotes: json['closingNotes'],
      isReadByOwner: json['isReadByOwner'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

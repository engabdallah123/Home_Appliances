class CreatePurchaseItemModel {
  final String productId;
  final String productName;
  final String? barcode;
  double quantity;
  double unitCost;
  double discount;
  double tax;
  DateTime? expiryDate;
  String? batchNumber;
  String? unit;
  bool isWeighable;
  int conversionFactor;
  String? parentUnit;
  String? baseUnit;
  int? shelfLifeDays;

  CreatePurchaseItemModel({
    required this.productId,
    required this.productName,
    this.barcode,
    this.quantity = 1,
    this.unitCost = 0,
    this.discount = 0,
    this.tax = 0,
    this.expiryDate,
    this.batchNumber,
    this.unit,
    this.isWeighable = false,
    this.conversionFactor = 1,
    this.parentUnit,
    this.baseUnit,
    this.shelfLifeDays,
  });

  double get total => (quantity * unitCost) - discount + tax;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'barcode': barcode,
    'quantity': quantity,
    'unitCost': unitCost,
    'discount': discount,
    'tax': tax,
    'expiryDate': expiryDate?.toIso8601String(),
    'batchNumber': batchNumber,
    'unit': unit,
  };
}

class CreatePurchaseModel {
  final String invoiceNumber;
  final String? internalNumber;
  final String supplierId;
  final DateTime? purchaseDate;
  final double discountAmount;
  final double taxAmount;
  final double paidAmount;
  final int paymentMethod; // 1: Cash, 2: Card, 3: Wallet, 4: Credit
  final String? notes;
  final List<CreatePurchaseItemModel> items;
  final String? createdByName;

  CreatePurchaseModel({
    required this.invoiceNumber,
    this.internalNumber,
    required this.supplierId,
    this.purchaseDate,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.paidAmount = 0,
    this.paymentMethod = 1,
    this.notes,
    required this.items,
    this.createdByName,
  });

  double get subTotal => items.fold(0.0, (sum, i) => sum + i.total);
  double get totalAmount => subTotal - discountAmount + taxAmount;
  double get remainingAmount => totalAmount - paidAmount;

  Map<String, dynamic> toJson() => {
    'invoiceNumber': invoiceNumber,
    'internalNumber': internalNumber,
    'supplierId': supplierId,
    'purchaseDate': (purchaseDate ?? DateTime.now()).toIso8601String(),
    'discountAmount': discountAmount,
    'taxAmount': taxAmount,
    'paidAmount': paidAmount,
    'paymentMethod': paymentMethod,
    'notes': notes,
    'items': items.map((i) => i.toJson()).toList(),
    if (createdByName != null && createdByName!.isNotEmpty) 'createdByName': createdByName,
  };
}

class PurchaseSummaryModel {
  final String id;
  final String invoiceNumber;
  final String? internalNumber;
  final String supplierId;
  final String? supplierName;
  final DateTime purchaseDate;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final int paymentMethod;
  final String? notes;
  final String syncStatus;
  final DateTime? syncedAt;
  final String? syncError;
  final DateTime createdAt;
  final int itemsCount;

  PurchaseSummaryModel({
    required this.id,
    required this.invoiceNumber,
    this.internalNumber,
    required this.supplierId,
    this.supplierName,
    required this.purchaseDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentMethod,
    this.notes,
    required this.syncStatus,
    this.syncedAt,
    this.syncError,
    required this.createdAt,
    required this.itemsCount,
  });

  factory PurchaseSummaryModel.fromJson(Map<String, dynamic> json) {
    return PurchaseSummaryModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      internalNumber: json['internalNumber'],
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'],
      purchaseDate: DateTime.tryParse(json['purchaseDate'] ?? '') ?? DateTime.now(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? 1,
      notes: json['notes'],
      syncStatus: json['syncStatus'] ?? 'PendingSync',
      syncedAt: json['syncedAt'] != null ? DateTime.tryParse(json['syncedAt']) : null,
      syncError: json['syncError'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      itemsCount: json['itemsCount'] ?? 0,
    );
  }
}

class PurchaseDetailModel {
  final String id;
  final String invoiceNumber;
  final String? internalNumber;
  final String supplierId;
  final String? supplierName;
  final DateTime purchaseDate;
  final double subTotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final int paymentMethod;
  final String? notes;
  final String? createdByName;
  final String syncStatus;
  final DateTime? syncedAt;
  final String? syncError;
  final int syncAttempts;
  final DateTime createdAt;
  final List<PurchaseItemDetailModel> items;

  PurchaseDetailModel({
    required this.id,
    required this.invoiceNumber,
    this.internalNumber,
    required this.supplierId,
    this.supplierName,
    required this.purchaseDate,
    required this.subTotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentMethod,
    this.notes,
    this.createdByName,
    required this.syncStatus,
    this.syncedAt,
    this.syncError,
    required this.syncAttempts,
    required this.createdAt,
    required this.items,
  });

  factory PurchaseDetailModel.fromJson(Map<String, dynamic> json) {
    var itemsList = <PurchaseItemDetailModel>[];
    if (json['items'] != null && json['items'] is List) {
      itemsList = (json['items'] as List)
          .map((i) => PurchaseItemDetailModel.fromJson(i))
          .toList();
    }

    return PurchaseDetailModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      internalNumber: json['internalNumber'],
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'],
      purchaseDate: DateTime.tryParse(json['purchaseDate'] ?? '') ?? DateTime.now(),
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? 1,
      notes: json['notes'],
      createdByName: json['createdByName'],
      syncStatus: json['syncStatus'] ?? 'PendingSync',
      syncedAt: json['syncedAt'] != null ? DateTime.tryParse(json['syncedAt']) : null,
      syncError: json['syncError'],
      syncAttempts: json['syncAttempts'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      items: itemsList,
    );
  }
}

class PurchaseItemDetailModel {
  final String id;
  final String productId;
  final String productName;
  final String? barcode;
  final double quantity;
  final double unitCost;
  final double discount;
  final double tax;
  final double total;
  final DateTime? expiryDate;
  final String? batchNumber;
  final String? unit;

  PurchaseItemDetailModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.barcode,
    required this.quantity,
    required this.unitCost,
    required this.discount,
    required this.tax,
    required this.total,
    this.expiryDate,
    this.batchNumber,
    this.unit,
  });

  factory PurchaseItemDetailModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemDetailModel(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      barcode: json['barcode'],
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate']) : null,
      batchNumber: json['batchNumber'],
      unit: json['unit'],
    );
  }
}

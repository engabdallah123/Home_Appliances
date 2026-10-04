class CartItemModel {
  final String productId;
  final String productName;
  final String? barcode;
  final String? modelNumber;
  final String? brandName;
  double quantity;
  double unitPrice;
  double discount;
  double tax;
  String? serialNumber;
  int warrantyPeriodMonths;
  double stockQuantity;

  CartItemModel({
    required this.productId,
    required this.productName,
    this.barcode,
    this.modelNumber,
    this.brandName,
    this.quantity = 1,
    required this.unitPrice,
    this.discount = 0,
    this.tax = 0,
    this.serialNumber,
    this.warrantyPeriodMonths = 12,
    this.stockQuantity = 0,
  });

  double get subTotal => quantity * unitPrice;
  double get total => subTotal - discount + tax;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'barcode': barcode,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'discount': discount,
        'tax': tax,
        'serialNumber': serialNumber,
        'modelNumber': modelNumber,
        'brandName': brandName,
        'warrantyPeriodMonths': warrantyPeriodMonths,
      };

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      barcode: json['barcode']?.toString(),
      modelNumber: json['modelNumber']?.toString(),
      brandName: json['brandName']?.toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      serialNumber: json['serialNumber']?.toString(),
      warrantyPeriodMonths: (json['warrantyPeriodMonths'] as num?)?.toInt() ?? 12,
      stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CreateSaleModel {
  final String? invoiceNumber;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final double discountAmount;
  final double taxAmount;
  final double paidAmount;
  final String paymentMethod; // Cash, Card, Installment, Credit
  final String? notes;
  final List<CartItemModel> items;

  // Delivery (خدمة التوصيل والتركيب للأجهزة الكبيرة)
  final bool isDelivery;
  final String? recipientName;
  final String? recipientPhone;
  final String? deliveryAddress;
  final String? deliveryFloor;
  final double deliveryFee;

  // Installment (التقسيط)
  final bool isInstallment;
  final String? guarantorName;
  final String? guarantorPhone;
  final String? guarantorNationalId;
  final String? guarantorAddress;
  final String? guarantorNotes;
  final double interestPercentage;
  final int numberOfMonths;

  // Layaway / Reservation (حجز مسبق)
  final bool isReserved;
  final DateTime? targetDeliveryDate;

  CreateSaleModel({
    this.invoiceNumber,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.paidAmount = 0,
    this.paymentMethod = "Cash",
    this.notes,
    required this.items,
    this.isDelivery = false,
    this.recipientName,
    this.recipientPhone,
    this.deliveryAddress,
    this.deliveryFloor,
    this.deliveryFee = 0,
    this.isInstallment = false,
    this.guarantorName,
    this.guarantorPhone,
    this.guarantorNationalId,
    this.guarantorAddress,
    this.guarantorNotes,
    this.interestPercentage = 0,
    this.numberOfMonths = 12,
    this.isReserved = false,
    this.targetDeliveryDate,
  });

  double get itemsSubTotal => items.fold(0.0, (sum, i) => sum + i.total);
  double get grandTotal => itemsSubTotal - discountAmount + taxAmount + (isDelivery ? deliveryFee : 0);
  double get remainingAmount => grandTotal - paidAmount;

  Map<String, dynamic> toJson() => {
        'invoiceNumber': invoiceNumber,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'discountAmount': discountAmount,
        'taxAmount': taxAmount,
        'paidAmount': paidAmount,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'items': items.map((i) => i.toJson()).toList(),
        'isDelivery': isDelivery,
        'recipientName': recipientName,
        'recipientPhone': recipientPhone,
        'deliveryAddress': deliveryAddress,
        'deliveryFloor': deliveryFloor,
        'deliveryFee': deliveryFee,
        'isInstallment': isInstallment,
        'guarantorName': guarantorName,
        'guarantorPhone': guarantorPhone,
        'guarantorNationalId': guarantorNationalId,
        'guarantorAddress': guarantorAddress,
        'guarantorNotes': guarantorNotes,
        'interestPercentage': interestPercentage,
        'numberOfMonths': numberOfMonths,
        'isReserved': isReserved,
        'targetDeliveryDate': targetDeliveryDate?.toIso8601String(),
      };
}

class SaleSummaryModel {
  final String id;
  final String invoiceNumber;
  final String? customerName;
  final String? customerPhone;
  final DateTime saleDate;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String paymentMethod;
  final String? notes;
  final String? createdByName;
  final bool isDelivery;
  final bool isInstallment;
  final bool isReserved;
  final String syncStatus;
  final DateTime? syncedAt;
  final String? syncError;
  final int itemsCount;
  final DateTime createdAt;

  SaleSummaryModel({
    required this.id,
    required this.invoiceNumber,
    this.customerName,
    this.customerPhone,
    required this.saleDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentMethod,
    this.notes,
    this.createdByName,
    this.isDelivery = false,
    this.isInstallment = false,
    this.isReserved = false,
    this.reservationStatus = 0,
    required this.syncStatus,
    this.syncedAt,
    this.syncError,
    this.itemsCount = 0,
    required this.createdAt,
  });

  factory SaleSummaryModel.fromJson(Map<String, dynamic> json) {
    return SaleSummaryModel(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      customerName: json['customerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      saleDate: json['saleDate'] != null
          ? DateTime.tryParse(json['saleDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
      notes: json['notes']?.toString(),
      createdByName: json['createdByName']?.toString(),
      isDelivery: json['isDelivery'] ?? false,
      isInstallment: json['isInstallment'] ?? false,
      isReserved: json['isReserved'] ?? false,
      reservationStatus: (json['reservationStatus'] as num?)?.toInt() ?? 0,
      syncStatus: json['syncStatus']?.toString() ?? 'PendingSync',
      syncedAt: json['syncedAt'] != null
          ? DateTime.tryParse(json['syncedAt'].toString())
          : null,
      syncError: json['syncError']?.toString(),
      itemsCount: (json['itemsCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SaleDetailModel {
  final String id;
  final String invoiceNumber;
  final String? customerName;
  final String? customerPhone;
  final DateTime saleDate;
  final double subTotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String paymentMethod;
  final String? notes;
  final String? createdByName;
  final bool isDelivery;
  final String? recipientName;
  final String? recipientPhone;
  final String? deliveryAddress;
  final double deliveryFee;
  final bool isInstallment;
  final int numberOfMonths;
  final bool isReserved;
  final String syncStatus;
  final DateTime? syncedAt;
  final String? syncError;
  final List<CartItemModel> items;

  SaleDetailModel({
    required this.id,
    required this.invoiceNumber,
    this.customerName,
    this.customerPhone,
    required this.saleDate,
    required this.subTotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentMethod,
    this.notes,
    this.createdByName,
    this.isDelivery = false,
    this.recipientName,
    this.recipientPhone,
    this.deliveryAddress,
    this.deliveryFee = 0,
    this.isInstallment = false,
    this.numberOfMonths = 12,
    this.isReserved = false,
    this.reservationStatus = 0,
    required this.syncStatus,
    this.syncedAt,
    this.syncError,
    required this.items,
  });

  factory SaleDetailModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    return SaleDetailModel(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      customerName: json['customerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      saleDate: json['saleDate'] != null
          ? DateTime.tryParse(json['saleDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
      notes: json['notes']?.toString(),
      createdByName: json['createdByName']?.toString(),
      isDelivery: json['isDelivery'] ?? false,
      recipientName: json['recipientName']?.toString(),
      recipientPhone: json['recipientPhone']?.toString(),
      deliveryAddress: json['deliveryAddress']?.toString(),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      isInstallment: json['isInstallment'] ?? false,
      numberOfMonths: (json['numberOfMonths'] as num?)?.toInt() ?? 12,
      isReserved: json['isReserved'] ?? false,
      reservationStatus: (json['reservationStatus'] as num?)?.toInt() ?? 0,
      syncStatus: json['syncStatus']?.toString() ?? 'PendingSync',
      syncedAt: json['syncedAt'] != null
          ? DateTime.tryParse(json['syncedAt'].toString())
          : null,
      syncError: json['syncError']?.toString(),
      items: rawItems.map((i) => CartItemModel.fromJson(i)).toList(),
    );
  }
}

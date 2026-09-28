import 'dart:convert';

class ReturnItemModel {
  final String id;
  final String productId;
  final String productName;
  final String? barcode;
  final double quantity;
  final double unitPrice;
  final double tax;
  final double total;
  final String? reason;

  ReturnItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.barcode,
    required this.quantity,
    required this.unitPrice,
    required this.tax,
    required this.total,
    this.reason,
  });

  factory ReturnItemModel.fromJson(Map<String, dynamic> json) {
    return ReturnItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? 'صنف مرتجع',
      barcode: json['barcode']?.toString(),
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toDouble() : 0.0,
      unitPrice: (json['unitPrice'] is num) ? (json['unitPrice'] as num).toDouble() : 0.0,
      tax: (json['tax'] is num) ? (json['tax'] as num).toDouble() : 0.0,
      total: (json['total'] is num) ? (json['total'] as num).toDouble() : 0.0,
      reason: json['reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'barcode': barcode,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'tax': tax,
        'total': total,
        'reason': reason,
      };
}

class ReturnModel {
  final String id;
  final String returnNumber;
  final String type; // "Sale" or "Purchase"
  final String? originalInvoiceNumber;
  final String? partyName;
  final String? partyPhone;
  final DateTime returnDate;
  final double totalAmount;
  final String? refundMethod;
  final String? reason;
  final String? notes;
  final int itemsCount;
  final List<ReturnItemModel> items;

  ReturnModel({
    required this.id,
    required this.returnNumber,
    required this.type,
    this.originalInvoiceNumber,
    this.partyName,
    this.partyPhone,
    required this.returnDate,
    required this.totalAmount,
    this.refundMethod,
    this.reason,
    this.notes,
    required this.itemsCount,
    required this.items,
  });

  bool get isSale => type.toLowerCase() == 'sale' || type.toLowerCase() == 'sales';
  bool get isPurchase => type.toLowerCase() == 'purchase' || type.toLowerCase() == 'purchases';

  factory ReturnModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    if (rawItems == null && json['itemsJson'] != null) {
      try {
        final itemsData = json['itemsJson'];
        if (itemsData is String && itemsData.isNotEmpty) {
          rawItems = jsonDecode(itemsData);
        } else if (itemsData is List) {
          rawItems = itemsData;
        }
      } catch (_) {}
    }

    List<ReturnItemModel> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems
          .map((i) => ReturnItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return ReturnModel(
      id: json['id']?.toString() ?? '',
      returnNumber: json['returnNumber']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Sale',
      originalInvoiceNumber: json['originalInvoiceNumber']?.toString(),
      partyName: json['partyName']?.toString(),
      partyPhone: json['partyPhone']?.toString(),
      returnDate: DateTime.tryParse(json['returnDate']?.toString() ?? '') ?? DateTime.now(),
      totalAmount: (json['totalAmount'] is num) ? (json['totalAmount'] as num).toDouble() : 0.0,
      refundMethod: json['refundMethod']?.toString(),
      reason: json['reason']?.toString(),
      notes: json['notes']?.toString(),
      itemsCount: (json['itemsCount'] is num)
          ? (json['itemsCount'] as num).toInt()
          : itemsList.length,
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'returnNumber': returnNumber,
        'type': type,
        'originalInvoiceNumber': originalInvoiceNumber,
        'partyName': partyName,
        'partyPhone': partyPhone,
        'returnDate': returnDate.toIso8601String(),
        'totalAmount': totalAmount,
        'refundMethod': refundMethod,
        'reason': reason,
        'notes': notes,
        'itemsCount': itemsCount,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

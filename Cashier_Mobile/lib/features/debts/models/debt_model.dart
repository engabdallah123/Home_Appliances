class DebtItemModel {
  final String id;
  final String type; // 'Customer' or 'Supplier'
  final String referenceId;
  final String invoiceNumber;
  final String entityName;
  final String? phone;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime date;

  DebtItemModel({
    required this.id,
    required this.type,
    required this.referenceId,
    required this.invoiceNumber,
    required this.entityName,
    this.phone,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.date,
  });

  factory DebtItemModel.fromJson(Map<String, dynamic> json) {
    return DebtItemModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'Customer',
      referenceId: json['referenceId'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      entityName: json['entityName'] ?? '',
      phone: json['phone'],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}

class GroupedDebtEntity {
  final String entityName;
  final String? phone;
  final String type; // 'Customer' or 'Supplier'
  final List<DebtItemModel> invoices;

  GroupedDebtEntity({
    required this.entityName,
    this.phone,
    required this.type,
    required this.invoices,
  });

  double get totalRemaining => invoices.fold(0.0, (sum, i) => sum + i.remainingAmount);
  double get totalAmount => invoices.fold(0.0, (sum, i) => sum + i.totalAmount);
  double get totalPaid => invoices.fold(0.0, (sum, i) => sum + i.paidAmount);
  int get invoicesCount => invoices.length;
}

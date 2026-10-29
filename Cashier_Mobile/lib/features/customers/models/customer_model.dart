import '../../debts/models/debt_model.dart';
import '../../sales/models/sale_model.dart';

class CustomerModel {
  final String name;
  final String? phone;
  final double totalSpent;
  final double totalDebt;
  final int invoicesCount;
  final DateTime? lastSaleDate;
  final bool hasDebt;

  CustomerModel({
    required this.name,
    this.phone,
    required this.totalSpent,
    required this.totalDebt,
    required this.invoicesCount,
    this.lastSaleDate,
    required this.hasDebt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      name: json['name']?.toString() ?? 'عميل عام',
      phone: json['phone']?.toString(),
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      totalDebt: (json['totalDebt'] as num?)?.toDouble() ?? 0.0,
      invoicesCount: (json['invoicesCount'] as num?)?.toInt() ?? 0,
      lastSaleDate: json['lastSaleDate'] != null
          ? DateTime.tryParse(json['lastSaleDate'].toString())
          : null,
      hasDebt: json['hasDebt'] ?? false,
    );
  }
}

class CustomerDossierModel {
  final String name;
  final String? phone;
  final double totalSpent;
  final double totalDebt;
  final List<SaleSummaryModel> sales;
  final List<DebtItemModel> debts;

  CustomerDossierModel({
    required this.name,
    this.phone,
    required this.totalSpent,
    required this.totalDebt,
    required this.sales,
    required this.debts,
  });

  factory CustomerDossierModel.fromJson(Map<String, dynamic> json) {
    final rawSales = json['sales'] as List? ?? [];
    final rawDebts = json['debts'] as List? ?? [];

    return CustomerDossierModel(
      name: json['name']?.toString() ?? 'عميل عام',
      phone: json['phone']?.toString(),
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      totalDebt: (json['totalDebt'] as num?)?.toDouble() ?? 0.0,
      sales: rawSales.map((s) => SaleSummaryModel.fromJson(s as Map<String, dynamic>)).toList(),
      debts: rawDebts.map((d) => DebtItemModel.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}


import '../../debts/models/debt_model.dart';
import '../../sales/models/sale_model.dart';

class CustomerModel {
  final String? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double totalSpent;
  final double totalDebt;
  final int invoicesCount;
  final DateTime? lastSaleDate;
  final bool hasDebt;

  CustomerModel({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.totalSpent,
    required this.totalDebt,
    required this.invoicesCount,
    this.lastSaleDate,
    required this.hasDebt,
  });

  double get balance => totalDebt;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? 'عميل عام',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
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


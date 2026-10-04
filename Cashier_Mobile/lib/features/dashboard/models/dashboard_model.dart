class DashboardStats {
  final double todaySalesAmount;
  final double todayProfitAmount;
  final double todayPurchasesAmount;
  final int todayPurchasesCount;
  final double todayExpensesAmount;
  final double monthSalesAmount;
  final double monthProfitAmount;
  final double monthPurchasesAmount;
  final int monthPurchasesCount;
  final double monthExpensesAmount;
  final double customerDebtsTotal;
  final double customerCreditDebtsTotal;
  final double installmentDebtsTotal;
  final int customerCreditDebtsCount;
  final int installmentContractsCount;
  final double supplierDebtsTotal;
  final int lowStockProductsCount;
  final int expiryAlertsCount;
  final int pendingSyncPurchasesCount;
  final int syncedPurchasesCount;
  final int failedSyncPurchasesCount;
  final int totalSuppliersCount;
  final int totalProductsCount;
  final String? monthlySalesJson;
  final double todayWasteLossAmount;
  final double monthWasteLossAmount;
  final double totalWasteLossAmount;
  final List<DashboardRecentPurchase> recentPurchases;

  DashboardStats({
    required this.todaySalesAmount,
    required this.todayProfitAmount,
    required this.todayPurchasesAmount,
    required this.todayPurchasesCount,
    required this.todayExpensesAmount,
    required this.monthSalesAmount,
    required this.monthProfitAmount,
    required this.monthPurchasesAmount,
    required this.monthPurchasesCount,
    required this.monthExpensesAmount,
    required this.customerDebtsTotal,
    this.customerCreditDebtsTotal = 0.0,
    this.installmentDebtsTotal = 0.0,
    this.customerCreditDebtsCount = 0,
    this.installmentContractsCount = 0,
    required this.supplierDebtsTotal,
    required this.lowStockProductsCount,
    required this.expiryAlertsCount,
    required this.pendingSyncPurchasesCount,
    required this.syncedPurchasesCount,
    required this.failedSyncPurchasesCount,
    required this.totalSuppliersCount,
    required this.totalProductsCount,
    this.monthlySalesJson,
    this.todayWasteLossAmount = 0.0,
    this.monthWasteLossAmount = 0.0,
    this.totalWasteLossAmount = 0.0,
    required this.recentPurchases,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    var recentsList = <DashboardRecentPurchase>[];
    if (json['recentPurchases'] != null && json['recentPurchases'] is List) {
      recentsList = (json['recentPurchases'] as List)
          .map((i) => DashboardRecentPurchase.fromJson(i))
          .toList();
    }

    return DashboardStats(
      todaySalesAmount: (json['todaySalesAmount'] as num?)?.toDouble() ?? 0.0,
      todayProfitAmount: (json['todayProfitAmount'] as num?)?.toDouble() ?? 0.0,
      todayPurchasesAmount: (json['todayPurchasesAmount'] as num?)?.toDouble() ?? 0.0,
      todayPurchasesCount: json['todayPurchasesCount'] ?? 0,
      todayExpensesAmount: (json['todayExpensesAmount'] as num?)?.toDouble() ?? 0.0,
      monthSalesAmount: (json['monthSalesAmount'] as num?)?.toDouble() ?? 0.0,
      monthProfitAmount: (json['monthProfitAmount'] as num?)?.toDouble() ?? 0.0,
      monthPurchasesAmount: (json['monthPurchasesAmount'] as num?)?.toDouble() ?? 0.0,
      monthPurchasesCount: json['monthPurchasesCount'] ?? 0,
      monthExpensesAmount: (json['monthExpensesAmount'] as num?)?.toDouble() ?? 0.0,
      customerDebtsTotal: (json['customerDebtsTotal'] as num?)?.toDouble() ?? 0.0,
      customerCreditDebtsTotal: (json['customerCreditDebtsTotal'] as num?)?.toDouble() ?? 0.0,
      installmentDebtsTotal: (json['installmentDebtsTotal'] as num?)?.toDouble() ?? 0.0,
      customerCreditDebtsCount: (json['customerCreditDebtsCount'] as num?)?.toInt() ?? 0,
      installmentContractsCount: (json['installmentContractsCount'] as num?)?.toInt() ?? 0,
      supplierDebtsTotal: (json['supplierDebtsTotal'] as num?)?.toDouble() ?? 0.0,
      lowStockProductsCount: json['lowStockProductsCount'] ?? 0,
      expiryAlertsCount: json['expiryAlertsCount'] ?? 0,
      pendingSyncPurchasesCount: json['pendingSyncPurchasesCount'] ?? 0,
      syncedPurchasesCount: json['syncedPurchasesCount'] ?? 0,
      failedSyncPurchasesCount: json['failedSyncPurchasesCount'] ?? 0,
      totalSuppliersCount: json['totalSuppliersCount'] ?? 0,
      totalProductsCount: json['totalProductsCount'] ?? 0,
      monthlySalesJson: json['monthlySalesJson'],
      todayWasteLossAmount: (json['todayWasteLossAmount'] as num?)?.toDouble() ?? 0.0,
      monthWasteLossAmount: (json['monthWasteLossAmount'] as num?)?.toDouble() ?? 0.0,
      totalWasteLossAmount: (json['totalWasteLossAmount'] as num?)?.toDouble() ?? 0.0,
      recentPurchases: recentsList,
    );
  }
}

class DashboardRecentPurchase {
  final String id;
  final String invoiceNumber;
  final String? supplierName;
  final DateTime purchaseDate;
  final double totalAmount;
  final String syncStatus;
  final int itemsCount;

  DashboardRecentPurchase({
    required this.id,
    required this.invoiceNumber,
    this.supplierName,
    required this.purchaseDate,
    required this.totalAmount,
    required this.syncStatus,
    required this.itemsCount,
  });

  factory DashboardRecentPurchase.fromJson(Map<String, dynamic> json) {
    return DashboardRecentPurchase(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      supplierName: json['supplierName'],
      purchaseDate: DateTime.tryParse(json['purchaseDate'] ?? '') ?? DateTime.now(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      syncStatus: json['syncStatus'] ?? 'PendingSync',
      itemsCount: json['itemsCount'] ?? 0,
    );
  }
}


import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiEndpoints {
  // Live Cloud Server URL
  static String get defaultBaseUrl => "https://homecashier.tryasp.net";

  // Auth
  static const String login = "/api/cloud/auth/login";
  static const String register = "/api/cloud/auth/register";
  static const String profile = "/api/cloud/auth/me";

  // Dashboard & Financial Reports
  static const String dashboard = "/api/cloud/dashboard";
  static const String monthlyReport = "/api/cloud/dashboard/monthly-report";

  // Users & Staff
  static const String users = "/api/cloud/auth/users";

  // Audit Logs (سجل الرقابة والعمليات)
  static const String auditLogs = "/api/cloud/audit";

  // Offers & Bride Packages (عروض وبكجات العروسة)
  static const String offers = "/api/cloud/offers";

  // Suppliers
  static const String suppliers = "/api/cloud/suppliers";

  // Categories
  static const String categories = "/api/cloud/categories";

  // Brands (الأجهزة الكهربائية والمنزلية)
  static const String brands = "/api/cloud/brands";
  static String brandDetails(String id) => "/api/cloud/brands/$id";

  // Products
  static const String products = "/api/cloud/products";
  static String productDetails(String id) => "/api/cloud/products/$id";
  static String productByBarcode(String barcode) => "/api/cloud/products/barcode/$barcode";

  // Debts
  static const String debts = "/api/cloud/debts";
  static const String payDebt = "/api/cloud/debts/pay";

  // Installments (الأقساط والعقود)
  static const String installments = "/api/cloud/installments";
  static String payInstallment(String id) => "/api/cloud/installments/$id/pay";
  static String paySaleInstallment(String id) => "/api/cloud/sales/$id/pay-installment";

  // Expenses
  static const String expenses = "/api/cloud/expenses";

  // Purchases
  static const String purchases = "/api/cloud/purchases";
  static String purchaseDetails(String id) => "/api/cloud/purchases/$id";
  static String retryPurchase(String id) => "/api/cloud/purchases/$id/retry";

  // Returns
  static const String returns = "/api/cloud/returns";
  static String returnDetails(String id) => "/api/cloud/returns/$id";

  // Sales & Mobile POS (المبيعات ونقاط البيع المتنقلة)
  static const String sales = "/api/cloud/sales";
  static String saleDetails(String id) => "/api/cloud/sales/$id";
}


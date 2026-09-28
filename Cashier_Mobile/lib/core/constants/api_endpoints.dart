
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiEndpoints {
  // Web/Desktop uses localhost:5100, Android emulator uses 10.0.2.2:5100, real phone uses LAN IP
  static String get defaultBaseUrl {
    if (kIsWeb) return "http://localhost:5100";
    try {
      if (Platform.isAndroid) return "http://10.0.2.2:5100";
    } catch (_) {}
    return "http://localhost:5100";
  }

  // Auth
  static const String login = "/api/cloud/auth/login";
  static const String profile = "/api/cloud/auth/me";

  // Dashboard
  static const String dashboard = "/api/cloud/dashboard";

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


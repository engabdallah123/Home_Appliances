import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../debts/models/debt_model.dart';
import '../../sales/models/sale_model.dart';
import '../models/customer_model.dart';

class CustomersProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;

  CustomerDossierModel? _currentDossier;
  bool _isLoadingDossier = false;
  String? _dossierError;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CustomerDossierModel? get currentDossier => _currentDossier;
  bool get isLoadingDossier => _isLoadingDossier;
  String? get dossierError => _dossierError;

  double get totalDebts => _customers.fold(0.0, (sum, c) => sum + c.totalDebt);
  double get totalSpent => _customers.fold(0.0, (sum, c) => sum + c.totalSpent);
  int get customersWithDebtCount => _customers.where((c) => c.hasDebt || c.totalDebt > 0).length;

  Future<void> fetchCustomers({bool refresh = false, String? search}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    if (refresh) notifyListeners();

    try {
      final queryParam = (search != null && search.trim().isNotEmpty)
          ? "?search=${Uri.encodeComponent(search.trim())}"
          : "";

      final response = await _apiClient.get("${ApiEndpoints.customers}$queryParam");

      if (response != null && response is List) {
        _customers = response.map((item) => CustomerModel.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        // Fallback: Aggregate from Cloud Sales & Debts
        await _aggregateCustomersFromSalesAndDebts(search);
      }
    } catch (e) {
      debugPrint("Error fetching customers directly, trying aggregation fallback: $e");
      try {
        await _aggregateCustomersFromSalesAndDebts(search);
      } catch (err) {
        _errorMessage = "تعذر تحميل بيانات العملاء: $err";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new customer from Mobile, saving it to Cloud API so it syncs down to Desktop
  Future<CustomerModel?> addCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final body = {
        'name': name.trim(),
        'phone': phone?.trim() ?? '',
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
      };

      final res = await _apiClient.post(ApiEndpoints.customers, body: body);

      if (res != null && res is Map<String, dynamic>) {
        final newCust = CustomerModel.fromJson(res);
        // Remove old entry with same phone if any
        _customers.removeWhere((c) => c.phone == newCust.phone || c.name.toLowerCase() == newCust.name.toLowerCase());
        _customers.insert(0, newCust);
        notifyListeners();
        return newCust;
      }
      return null;
    } catch (e) {
      debugPrint("Error adding customer: $e");
      rethrow;
    }
  }

  /// Graceful aggregation fallback if dedicated customer endpoint is unavailable
  Future<void> _aggregateCustomersFromSalesAndDebts(String? search) async {
    final Map<String, (String name, String? phone, double spent, double debt, int count, DateTime? lastDate)> map = {};

    try {
      final salesRes = await _apiClient.get("${ApiEndpoints.sales}?pageSize=100");
      if (salesRes != null && salesRes is List) {
        for (final item in salesRes) {
          final cName = item['customerName']?.toString();
          if (cName == null || cName.trim().isEmpty || cName == "Walk-in Customer") continue;

          final cPhone = item['customerPhone']?.toString();
          final key = (cPhone != null && cPhone.isNotEmpty) ? cPhone : cName.trim();
          final total = (item['totalAmount'] as num?)?.toDouble() ?? 0.0;
          final sDate = item['saleDate'] != null ? DateTime.tryParse(item['saleDate'].toString()) : null;

          if (!map.containsKey(key)) {
            map[key] = (cName.trim(), cPhone, total, 0.0, 1, sDate);
          } else {
            final old = map[key]!;
            final newDate = (old.$6 == null || (sDate != null && sDate.isAfter(old.$6!))) ? sDate : old.$6;
            map[key] = (old.$1, old.$2 ?? cPhone, old.$3 + total, old.$4, old.$5 + 1, newDate);
          }
        }
      }
    } catch (_) {}

    try {
      final debtsRes = await _apiClient.get("${ApiEndpoints.debts}?type=Customer&pageSize=100");
      if (debtsRes != null && debtsRes is List) {
        for (final item in debtsRes) {
          final eName = item['entityName']?.toString() ?? 'عميل';
          final ePhone = item['phone']?.toString();
          final remaining = (item['remainingAmount'] as num?)?.toDouble() ?? 0.0;
          final key = (ePhone != null && ePhone.isNotEmpty) ? ePhone : eName.trim();

          if (!map.containsKey(key)) {
            map[key] = (eName.trim(), ePhone, 0.0, remaining, 0, null);
          } else {
            final old = map[key]!;
            map[key] = (old.$1, old.$2 ?? ePhone, old.$3, old.$4 + remaining, old.$5, old.$6);
          }
        }
      }
    } catch (_) {}

    var list = map.values.map((v) => CustomerModel(
      name: v.$1,
      phone: v.$2,
      totalSpent: v.$3,
      totalDebt: v.$4,
      invoicesCount: v.$5,
      lastSaleDate: v.$6,
      hasDebt: v.$4 > 0,
    )).toList();

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list.where((c) =>
          c.name.toLowerCase().contains(q) ||
          (c.phone != null && c.phone!.contains(q))).toList();
    }

    list.sort((a, b) {
      final cmpDebt = b.totalDebt.compareTo(a.totalDebt);
      if (cmpDebt != 0) return cmpDebt;
      return a.name.compareTo(b.name);
    });

    _customers = list;
  }

  Future<void> fetchCustomerDossier(String name, String? phone) async {
    _isLoadingDossier = true;
    _dossierError = null;
    _currentDossier = null;
    notifyListeners();

    try {
      final nameParam = Uri.encodeComponent(name.trim());
      final phoneParam = phone != null ? Uri.encodeComponent(phone.trim()) : "";
      final url = "${ApiEndpoints.customerDossier}?name=$nameParam&phone=$phoneParam";

      final response = await _apiClient.get(url);
      if (response != null && response is Map<String, dynamic>) {
        _currentDossier = CustomerDossierModel.fromJson(response);
      } else {
        // Fallback: Fetch sales & debts and filter locally
        await _buildDossierLocally(name, phone);
      }
    } catch (e) {
      debugPrint("Error fetching customer dossier directly: $e");
      try {
        await _buildDossierLocally(name, phone);
      } catch (err) {
        _dossierError = "تعذر استرجاع ملف العميل: $err";
      }
    } finally {
      _isLoadingDossier = false;
      notifyListeners();
    }
  }

  Future<void> _buildDossierLocally(String name, String? phone) async {
    List<SaleSummaryModel> matchedSales = [];
    List<DebtItemModel> matchedDebts = [];

    try {
      final salesRes = await _apiClient.get("${ApiEndpoints.sales}?search=${Uri.encodeComponent(name)}&pageSize=50");
      if (salesRes != null && salesRes is List) {
        matchedSales = salesRes
            .map((s) => SaleSummaryModel.fromJson(s as Map<String, dynamic>))
            .where((s) => (s.customerName != null && s.customerName!.trim() == name.trim()) ||
                          (phone != null && s.customerPhone != null && s.customerPhone!.trim() == phone.trim()))
            .toList();
      }
    } catch (_) {}

    try {
      final debtsRes = await _apiClient.get("${ApiEndpoints.debts}?type=Customer&search=${Uri.encodeComponent(name)}&pageSize=50");
      if (debtsRes != null && debtsRes is List) {
        matchedDebts = debtsRes
            .map((d) => DebtItemModel.fromJson(d as Map<String, dynamic>))
            .where((d) => d.entityName.trim() == name.trim() ||
                          (phone != null && d.phone != null && d.phone!.trim() == phone.trim()))
            .toList();
      }
    } catch (_) {}

    final totalSpent = matchedSales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalDebt = matchedDebts.fold(0.0, (sum, d) => sum + d.remainingAmount);

    _currentDossier = CustomerDossierModel(
      name: name,
      phone: phone,
      totalSpent: totalSpent,
      totalDebt: totalDebt,
      sales: matchedSales,
      debts: matchedDebts,
    );
  }
}

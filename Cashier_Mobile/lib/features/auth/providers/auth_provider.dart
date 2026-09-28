import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/auth_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  Map<String, String?> _userData = {};
  Map<String, dynamic> _storeSettings = {};
  String _currentServerUrl = ApiEndpoints.defaultBaseUrl;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, String?> get userData => _userData;
  Map<String, dynamic> get storeSettings => _storeSettings;
  String get currentServerUrl => _currentServerUrl;
  String get userName => _userData['fullName'] ?? 'صاحب المحل';
  String get shopName {
    if (_storeSettings['storeName'] != null && _storeSettings['storeName'].toString().trim().isNotEmpty) {
      return _storeSettings['storeName'].toString().trim();
    }
    return _userData['tenantName'] ?? 'المتجر الرئيسي';
  }
  String get shopAddress => _storeSettings['address']?.toString() ?? '';
  String get shopPhone => _storeSettings['phone']?.toString() ?? '';
  String get shopCurrency => _storeSettings['currency']?.toString() ?? 'ج.م';
  double get shopTaxRate => (_storeSettings['taxRate'] as num?)?.toDouble() ?? 0.0;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _currentServerUrl = await AppStorage.getBaseUrl();
    _isAuthenticated = await AppStorage.isLoggedIn();
    if (_isAuthenticated) {
      _userData = await AppStorage.getUserData();
      await fetchStoreSettings();
    }
    notifyListeners();
  }

  Future<void> fetchStoreSettings() async {
    try {
      final res = await _apiClient.get('/api/cloud/store-settings');
      if (res != null && res is Map<String, dynamic>) {
        _storeSettings = res;
        if (res['storeName'] != null) {
          _userData['tenantName'] = res['storeName'].toString();
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> login(String username, String password, [String? shopCode]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final req = LoginRequest(
        username: username,
        password: password,
        shopCode: shopCode,
      );

      final response = await _apiClient.post(
        ApiEndpoints.login,
        body: req.toJson(),
        requiresAuth: false,
      );

      if (response != null && response is Map<String, dynamic>) {
        final authData = AuthResponse.fromJson(response);

        await AppStorage.asyncSaveAuthSession(
          token: authData.token,
          userId: authData.userId,
          fullName: authData.fullName,
          role: authData.role,
          tenantId: authData.tenantId,
          tenantName: authData.tenantName,
          tenantCode: authData.tenantCode,
        );

        _isAuthenticated = true;
        _userData = await AppStorage.getUserData();
        await fetchStoreSettings();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw ApiException("فشل تسجيل الدخول، استجابة غير متوقعة من الخادم.");
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> setServerUrl(String url) async {
    await AppStorage.setBaseUrl(url);
    _currentServerUrl = await AppStorage.getBaseUrl();
    notifyListeners();
  }

  Future<void> logout() async {
    await AppStorage.clearSession();
    _isAuthenticated = false;
    _userData = {};
    notifyListeners();
  }
}

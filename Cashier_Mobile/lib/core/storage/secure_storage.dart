import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';

class AppStorage {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyFullName = 'full_name';
  static const String _keyRole = 'user_role';
  static const String _keyTenantId = 'tenant_id';
  static const String _keyTenantName = 'tenant_name';
  static const String _keyTenantCode = 'tenant_code';
  static const String _keyBaseUrl = 'server_base_url';

  // Save session
  static asyncSaveAuthSession({
    required String token,
    required String userId,
    required String fullName,
    required String role,
    required String tenantId,
    required String tenantName,
    required String tenantCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyFullName, fullName);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyTenantId, tenantId);
    await prefs.setString(_keyTenantName, tenantName);
    await prefs.setString(_keyTenantCode, tenantCode);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_keyBaseUrl);
    if (url == null || url.trim().isEmpty || url.contains("poscashier.runasp.net")) {
      return ApiEndpoints.defaultBaseUrl;
    }
    return url;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    var cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    await prefs.setString(_keyBaseUrl, cleanUrl);
  }

  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_keyToken),
      'userId': prefs.getString(_keyUserId),
      'fullName': prefs.getString(_keyFullName),
      'role': prefs.getString(_keyRole),
      'tenantId': prefs.getString(_keyTenantId),
      'tenantName': prefs.getString(_keyTenantName),
      'tenantCode': prefs.getString(_keyTenantCode),
    };
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyFullName);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyTenantId);
    await prefs.remove(_keyTenantName);
    await prefs.remove(_keyTenantCode);
  }
}

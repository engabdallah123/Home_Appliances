import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await AppStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Uri _buildUri(String baseUrl, String endpoint, [Map<String, dynamic>? queryParams]) {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    var uri = Uri.parse('$cleanBase$cleanEndpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));
    }
    return uri;
  }

  Future<dynamic> get(String endpoint, {bool requiresAuth = true, Map<String, dynamic>? queryParams}) async {
    final baseUrl = await AppStorage.getBaseUrl();
    final uri = _buildUri(baseUrl, endpoint, queryParams);

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, bool requiresAuth = true}) async {
    final baseUrl = await AppStorage.getBaseUrl();
    final uri = _buildUri(baseUrl, endpoint);

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 20));

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body, bool requiresAuth = true}) async {
    final baseUrl = await AppStorage.getBaseUrl();
    final uri = _buildUri(baseUrl, endpoint);

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 20));

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> patch(String endpoint, {dynamic body, bool requiresAuth = true}) async {
    final baseUrl = await AppStorage.getBaseUrl();
    final uri = _buildUri(baseUrl, endpoint);

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 20));

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    final baseUrl = await AppStorage.getBaseUrl();
    final uri = _buildUri(baseUrl, endpoint);

    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.delete(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        return response.body;
      }
    }

    String errorMessage = "حدث خطأ غير متوقع أثناء الاتصال بالخادم.";
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded.containsKey('message')) {
        errorMessage = decoded['message'];
      } else if (decoded is Map && decoded.containsKey('title')) {
        errorMessage = decoded['title'];
      }
    } catch (_) {
      if (response.body.isNotEmpty) errorMessage = response.body;
    }

    if (response.statusCode == 401) {
      throw ApiException("انتهت جلسة تسجيل الدخول، يرجى تسجيل الدخول مجدداً.", 401);
    } else if (response.statusCode == 404) {
      throw ApiException("البيانات المطلوبة غير متوفرة.", 404);
    } else if (response.statusCode == 400) {
      throw ApiException(errorMessage, 400);
    } else if (response.statusCode >= 500) {
      throw ApiException("خطأ في الخادم السحابي. يرجى المحاولة لاحقاً.", response.statusCode);
    }

    throw ApiException(errorMessage, response.statusCode);
  }

  void _handleError(dynamic error) {
    if (error is ApiException) {
      throw error;
    }
    throw ApiException("تعذر الاتصال بالسيرفر السحابي. تحقق من اتصال الإنترنت أو إعدادات السيرفر.");
  }
}

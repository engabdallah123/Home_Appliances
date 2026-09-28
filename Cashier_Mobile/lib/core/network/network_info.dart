import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../storage/secure_storage.dart';

class NetworkInfo with ChangeNotifier {
  static final NetworkInfo _instance = NetworkInfo._internal();
  factory NetworkInfo() => _instance;

  bool _isOnline = true;
  Timer? _pollingTimer;

  bool get isOnline => _isOnline;

  NetworkInfo._internal() {
    startMonitoring();
  }

  void startMonitoring() {
    checkConnection();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      checkConnection();
    });
  }

  Future<bool> checkConnection() async {
    try {
      final baseUrl = await AppStorage.getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/sync/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      final onlineNow = response.statusCode == 200;
      if (_isOnline != onlineNow) {
        _isOnline = onlineNow;
        notifyListeners();
      }
      return _isOnline;
    } catch (_) {
      if (_isOnline) {
        _isOnline = false;
        notifyListeners();
      }
      return false;
    }
  }

  void stopMonitoring() {
    _pollingTimer?.cancel();
  }
}

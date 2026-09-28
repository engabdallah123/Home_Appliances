import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/expense_model.dart';

class ExpensesProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;
  int? _currentMonth;
  int? _currentYear;
  String? _errorMessage;
  double _totalAmount = 0;
  List<ExpenseModel> _expenses = [];

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  double get totalAmount => _totalAmount;
  List<ExpenseModel> get expenses => _expenses;

  Future<void> fetchExpenses({int? month, int? year, bool refresh = true}) async {
    if (refresh) {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
      _currentMonth = month;
      _currentYear = year;
      notifyListeners();
    }

    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'pageSize': _pageSize,
      };
      if (_currentMonth != null) queryParams['month'] = _currentMonth;
      if (_currentYear != null) queryParams['year'] = _currentYear;

      final response = await _apiClient.get(ApiEndpoints.expenses, queryParams: queryParams);

      if (response != null && response is Map<String, dynamic>) {
        _totalAmount = (response['totalAmount'] as num?)?.toDouble() ?? 0.0;
        List<ExpenseModel> loaded = [];
        if (response['items'] != null && response['items'] is List) {
          loaded = (response['items'] as List).map((e) => ExpenseModel.fromJson(e)).toList();
        }

        if (refresh) {
          _expenses = loaded;
        } else {
          _expenses.addAll(loaded);
        }

        if (response['hasMore'] != null) {
          _hasMore = response['hasMore'] == true;
        } else {
          _hasMore = loaded.length >= _pageSize;
        }
      } else {
        if (refresh) _expenses = [];
        _hasMore = false;
      }

      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _isLoadingMore = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchMoreExpenses() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();
    await fetchExpenses(month: _currentMonth, year: _currentYear, refresh: false);
  }

  Future<bool> createExpense({
    required String title,
    required double amount,
    String? category,
    DateTime? date,
    String? notes,
  }) async {
    try {
      final body = {
        'title': title.trim(),
        'amount': amount,
        'category': category?.trim(),
        'date': (date ?? DateTime.now()).toIso8601String(),
        'notes': notes?.trim(),
      };

      final response = await _apiClient.post(ApiEndpoints.expenses, body: body);
      if (response != null) {
        await fetchExpenses();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

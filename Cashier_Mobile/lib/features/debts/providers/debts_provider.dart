import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/debt_model.dart';

class DebtsProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;
  String? _currentSearch;
  String? _errorMessage;

  double _totalCustomerDebts = 0;
  double _totalSupplierDebts = 0;
  double _netBalance = 0;
  List<DebtItemModel> _debts = [];
  String _activeTab = 'Customer'; // 'Customer' or 'Supplier'

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  double get totalCustomerDebts => _totalCustomerDebts;
  double get totalSupplierDebts => _totalSupplierDebts;
  double get netBalance => _netBalance;
  List<DebtItemModel> get debts => _debts;
  String get activeTab => _activeTab;

  void setActiveTab(String tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    fetchDebts(search: _currentSearch, refresh: true);
  }

  Future<void> fetchDebts({String? search, bool refresh = true}) async {
    if (refresh) {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
      _currentSearch = search;
      notifyListeners();
    }

    try {
      final queryParams = <String, dynamic>{
        'type': _activeTab,
        'page': _currentPage,
        'pageSize': _pageSize,
      };
      if (_currentSearch != null && _currentSearch!.trim().isNotEmpty) {
        queryParams['search'] = _currentSearch!.trim();
      }

      final response = await _apiClient.get(ApiEndpoints.debts, queryParams: queryParams);

      if (response != null && response is Map<String, dynamic>) {
        _totalCustomerDebts = (response['totalCustomerDebts'] as num?)?.toDouble() ?? 0.0;
        _totalSupplierDebts = (response['totalSupplierDebts'] as num?)?.toDouble() ?? 0.0;
        _netBalance = (response['netBalance'] as num?)?.toDouble() ?? 0.0;

        List<DebtItemModel> loadedItems = [];
        if (response['items'] != null && response['items'] is List) {
          loadedItems = (response['items'] as List).map((d) => DebtItemModel.fromJson(d)).toList();
        }

        if (refresh) {
          _debts = loadedItems;
        } else {
          _debts.addAll(loadedItems);
        }

        if (response['hasMore'] != null) {
          _hasMore = response['hasMore'] == true;
        } else {
          _hasMore = loadedItems.length >= _pageSize;
        }
      } else {
        if (refresh) _debts = [];
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

  Future<void> fetchMoreDebts() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();
    await fetchDebts(search: _currentSearch, refresh: false);
  }

  Future<bool> payDebt({
    required String debtType,
    required String referenceId,
    required double amount,
    String? notes,
  }) async {
    try {
      final body = {
        'debtType': debtType,
        'referenceId': referenceId,
        'amount': amount,
        'notes': notes,
      };

      final response = await _apiClient.post(ApiEndpoints.payDebt, body: body);
      if (response != null && response['success'] == true) {
        await fetchDebts(search: _currentSearch, refresh: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/return_model.dart';

class ReturnsProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<ReturnModel> _returns = [];
  String _activeTypeFilter = 'All'; // 'All', 'Sale', 'Purchase'
  String _searchQuery = '';
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  List<ReturnModel> get returns {
    if (_activeTypeFilter == 'All') return _returns;
    final filter = _activeTypeFilter.toLowerCase();
    if (filter == 'sale' || filter == 'sales') {
      return _returns.where((r) => r.isSale).toList();
    }
    if (filter == 'purchase' || filter == 'purchases') {
      return _returns.where((r) => r.isPurchase).toList();
    }
    return _returns.where((r) => r.type.toLowerCase() == filter).toList();
  }
  String get activeTypeFilter => _activeTypeFilter;
  String get searchQuery => _searchQuery;
  bool get hasMore => _hasMore;

  double get totalSalesReturnsAmount => _returns
      .where((r) => r.isSale)
      .fold(0.0, (sum, item) => sum + item.totalAmount);

  double get totalPurchasesReturnsAmount => _returns
      .where((r) => r.isPurchase)
      .fold(0.0, (sum, item) => sum + item.totalAmount);

  int get salesReturnsCount => _returns.where((r) => r.isSale).length;
  int get purchasesReturnsCount => _returns.where((r) => r.isPurchase).length;

  void setTypeFilter(String filter) {
    if (_activeTypeFilter == filter) return;
    _activeTypeFilter = filter;
    notifyListeners();
  }

  Future<void> fetchReturns({bool refresh = true, String? search}) async {
    if (refresh) {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
      _errorMessage = null;
    } else {
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
    }
    notifyListeners();

    if (search != null) {
      _searchQuery = search;
    }

    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'pageSize': _pageSize,
      };

      if (_searchQuery.trim().isNotEmpty) {
        queryParams['search'] = _searchQuery.trim();
      }

      final response = await _apiClient.get(ApiEndpoints.returns, queryParams: queryParams);

      if (response != null && response is Map<String, dynamic>) {
        final rawItems = response['returns'] ?? response['items'];
        List<ReturnModel> fetched = [];
        if (rawItems is List) {
          fetched = rawItems.map((item) => ReturnModel.fromJson(item as Map<String, dynamic>)).toList();
        }

        if (refresh) {
          _returns = fetched;
        } else {
          _returns.addAll(fetched);
        }

        _hasMore = fetched.length >= _pageSize;
        if (_hasMore) {
          _currentPage++;
        }
      } else {
        if (refresh) _returns = [];
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

  Future<void> fetchMoreReturns() async {
    await fetchReturns(refresh: false);
  }
}

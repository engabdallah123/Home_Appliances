import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/purchase_model.dart';

class PurchasesProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isCreating = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;
  String? _currentSearch;
  String? _errorMessage;
  List<PurchaseSummaryModel> _purchases = [];
  PurchaseDetailModel? _selectedPurchase;
  String _selectedFilter = 'all'; // all, PendingSync, Synced, SyncFailed

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isCreating => _isCreating;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  List<PurchaseSummaryModel> get purchases => _purchases;
  PurchaseDetailModel? get selectedPurchase => _selectedPurchase;
  String get selectedFilter => _selectedFilter;

  void setFilter(String filter) {
    _selectedFilter = filter;
    fetchPurchases(status: filter == 'all' ? null : filter, search: _currentSearch, refresh: true);
  }

  Future<void> fetchPurchases({String? status, String? search, bool refresh = true}) async {
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
        'page': _currentPage,
        'pageSize': _pageSize,
      };
      if (status != null && status != 'all') queryParams['status'] = status;
      if (_currentSearch != null && _currentSearch!.trim().isNotEmpty) queryParams['search'] = _currentSearch!.trim();

      final response = await _apiClient.get(ApiEndpoints.purchases, queryParams: queryParams);

      if (response != null && response is Map<String, dynamic> && response['items'] != null) {
        final loaded = (response['items'] as List)
            .map((item) => PurchaseSummaryModel.fromJson(item))
            .toList();

        if (refresh) {
          _purchases = loaded;
        } else {
          _purchases.addAll(loaded);
        }

        _hasMore = loaded.length >= _pageSize;
      } else {
        if (refresh) _purchases = [];
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

  Future<void> fetchMorePurchases() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();
    await fetchPurchases(
      status: _selectedFilter == 'all' ? null : _selectedFilter,
      search: _currentSearch,
      refresh: false,
    );
  }

  Future<PurchaseDetailModel?> fetchPurchaseDetails(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiEndpoints.purchaseDetails(id));
      if (response != null && response is Map<String, dynamic>) {
        _selectedPurchase = PurchaseDetailModel.fromJson(response);
      }
      _isLoading = false;
      notifyListeners();
      return _selectedPurchase;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> createPurchase(CreatePurchaseModel req) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.purchases,
        body: req.toJson(),
      );

      _isCreating = false;
      notifyListeners();

      // Refresh list after creation
      await fetchPurchases(status: _selectedFilter == 'all' ? null : _selectedFilter);
      return response != null;
    } catch (e) {
      _isCreating = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> retrySync(String id) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.retryPurchase(id));
      if (response != null) {
        await fetchPurchaseDetails(id);
        await fetchPurchases(status: _selectedFilter == 'all' ? null : _selectedFilter);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

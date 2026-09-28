import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/supplier_model.dart';

class SuppliersProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isAdding = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;
  String? _currentSearch;
  String? _errorMessage;
  List<SupplierModel> _suppliers = [];

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isAdding => _isAdding;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  List<SupplierModel> get suppliers => _suppliers;

  Future<void> fetchSuppliers({String? search, bool refresh = true}) async {
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
      if (_currentSearch != null && _currentSearch!.trim().isNotEmpty) {
        queryParams['search'] = _currentSearch!.trim();
      }

      final response = await _apiClient.get(ApiEndpoints.suppliers, queryParams: queryParams);

      if (response != null && response is List) {
        final loaded = response.map((s) => SupplierModel.fromJson(s)).toList();
        if (refresh) {
          _suppliers = loaded;
        } else {
          _suppliers.addAll(loaded);
        }
        _hasMore = loaded.length >= _pageSize;
      } else {
        if (refresh) _suppliers = [];
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

  Future<void> fetchMoreSuppliers() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();
    await fetchSuppliers(search: _currentSearch, refresh: false);
  }

  Future<SupplierModel?> addSupplier(CreateSupplierRequest req) async {
    _isAdding = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.suppliers,
        body: req.toJson(),
      );

      _isAdding = false;

      if (response != null && response is Map<String, dynamic>) {
        final newSupplier = SupplierModel.fromJson(response);
        _suppliers.insert(0, newSupplier);
        notifyListeners();
        return newSupplier;
      }
      return null;
    } catch (e) {
      _isAdding = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}

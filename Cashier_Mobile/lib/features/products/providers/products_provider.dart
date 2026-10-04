import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/brand_model.dart';
import '../models/product_model.dart';

class ProductsProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;
  String? _currentSearch;
  String? _errorMessage;
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  String? _selectedCategoryId;
  String? _selectedBrandId;
  String _activeFilter = 'all'; // all, appliances, low_stock, weighable, expiry

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  List<BrandModel> get brands => _brands;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedBrandId => _selectedBrandId;
  String get activeFilter => _activeFilter;

  void setSelectedCategory(String? catId) {
    _selectedCategoryId = catId;
    fetchProducts(search: _currentSearch);
  }

  void setSelectedBrand(String? brandId) {
    _selectedBrandId = brandId;
    fetchProducts(search: _currentSearch);
  }

  void setActiveFilter(String filter) {
    _activeFilter = filter;
    fetchProducts(search: _currentSearch);
  }

  Future<void> fetchCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.categories);
      if (response != null && response is List) {
        _categories = response.map((c) => CategoryModel.fromJson(c)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchBrands() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.brands);
      if (response != null && response is List) {
        _brands = response.map((b) => BrandModel.fromJson(b)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> createCategory(String nameAr, String? nameEn) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.categories,
        body: {'nameAr': nameAr.trim(), 'nameEn': nameEn?.trim()},
      );
      if (response != null && response is Map<String, dynamic>) {
        final newCat = CategoryModel.fromJson(response);
        _categories.add(newCat);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<BrandModel?> createBrand(CreateBrandRequest req) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.brands,
        body: req.toJson(),
      );
      if (response != null && response is Map<String, dynamic>) {
        final newBrand = BrandModel.fromJson(response);
        _brands.add(newBrand);
        notifyListeners();
        return newBrand;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _buildFilterParams(int page, String? search) {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': _pageSize,
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
      queryParams['categoryId'] = _selectedCategoryId;
    }
    if (_selectedBrandId != null && _selectedBrandId!.isNotEmpty) {
      queryParams['brandId'] = _selectedBrandId;
    }
    if (_activeFilter == 'low_stock') {
      queryParams['lowStockOnly'] = true;
    } else if (_activeFilter == 'warranty') {
      queryParams['hasWarrantyOnly'] = true;
    } else if (_activeFilter == 'serial') {
      queryParams['hasSerialNumberOnly'] = true;
    }
    return queryParams;
  }

  Future<void> fetchProducts({String? search, bool refresh = true}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _currentSearch = search;
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final queryParams = _buildFilterParams(_currentPage, _currentSearch);
      final response = await _apiClient.get(ApiEndpoints.products, queryParams: queryParams);

      if (response != null && response is List) {
        final loaded = response.map((p) => ProductModel.fromJson(p)).toList();
        _products = loaded;
        if (loaded.length < _pageSize) {
          _hasMore = false;
        }
      } else {
        _products = [];
        _hasMore = false;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchMoreProducts() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final queryParams = _buildFilterParams(nextPage, _currentSearch);
      final response = await _apiClient.get(ApiEndpoints.products, queryParams: queryParams);

      if (response != null && response is List) {
        final moreItems = response.map((p) => ProductModel.fromJson(p)).toList();
        if (moreItems.isNotEmpty) {
          _products.addAll(moreItems);
          _currentPage = nextPage;
        }
        if (moreItems.length < _pageSize) {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }

      _isLoadingMore = false;
      notifyListeners();
    } catch (_) {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<ProductModel?> fetchByBarcode(String barcode) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.productByBarcode(barcode.trim()));
      if (response != null && response is Map<String, dynamic>) {
        return ProductModel.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveProduct(ProductModel product, {bool isEdit = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = product.toJson();

      dynamic response;
      if (isEdit) {
        response = await _apiClient.put(ApiEndpoints.productDetails(product.id), body: body);
      } else {
        response = await _apiClient.post(ApiEndpoints.products, body: body);
      }

      if (response != null) {
        await fetchProducts();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.productDetails(id));
      if (response != null) {
        _products.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

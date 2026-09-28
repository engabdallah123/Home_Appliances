import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/brand_model.dart';

class BrandsProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<BrandModel> _brands = [];
  String? _searchQuery;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<BrandModel> get brands {
    if (_searchQuery == null || _searchQuery!.trim().isEmpty) {
      return _brands;
    }
    final q = _searchQuery!.trim().toLowerCase();
    return _brands.where((b) {
      final name = b.name.toLowerCase();
      final ar = (b.nameAr ?? '').toLowerCase();
      final en = (b.nameEn ?? '').toLowerCase();
      final desc = (b.description ?? '').toLowerCase();
      return name.contains(q) || ar.contains(q) || en.contains(q) || desc.contains(q);
    }).toList();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchBrands({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiEndpoints.brands);
      if (response != null && response is List) {
        _brands = response.map((b) => BrandModel.fromJson(b)).toList();
      } else {
        _brands = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<BrandModel?> createBrand(CreateBrandRequest req) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.brands,
        body: req.toJson(),
      );

      _isSaving = false;
      if (response != null && response is Map<String, dynamic>) {
        final newBrand = BrandModel.fromJson(response);
        _brands.insert(0, newBrand);
        notifyListeners();
        return newBrand;
      }
      notifyListeners();
      return null;
    } catch (e) {
      _isSaving = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteBrand(String id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.brandDetails(id));
      if (response != null) {
        _brands.removeWhere((b) => b.id == id);
        notifyListeners();
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
